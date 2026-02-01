{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.wireguard;
in
{
  options.services.mitchty.wireguard = {
    enable = mkEnableOption "Enable WireGuard VPN";

    role = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      description = "Whether this host is a WireGuard server or client";
    };

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name";
    };

    address = mkOption {
      type = types.listOf types.str;
      description = "WireGuard interface IP addresses";
    };

    privateKeyFile = mkOption {
      type = types.str;
      description = "Path to the private key file";
    };

    listenPort = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Port to listen on: server only";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "DNS servers to use when connected more future plans ";
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            publicKey = mkOption {
              type = types.str;
              description = "Peer's public key";
            };

            allowedIPs = mkOption {
              type = types.listOf types.str;
              description = "IP addresses this peer is allowed to send/receive";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Peer endpoint host:port";
            };

            persistentKeepalive = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Interval in seconds to send keepalive packets";
            };
          };
        }
      );
      default = [ ];
      description = "List of WireGuard peers";
    };

    postSetup = mkOption {
      type = types.lines;
      default = "";
      description = "Commands to run after the WireGuard interface is set up";
    };

    preShutdown = mkOption {
      type = types.lines;
      default = "";
      description = "Commands to run before the WireGuard interface is shut down";
    };

    enableNat = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NAT/masquerading for WireGuard clients? server only obvs dum dum";
    };

    natInterface = mkOption {
      type = types.str;
      default = "br0";
      description = "Interface to NAT WireGuard traffic to, e.g., br0, eth0, enp1s0";
    };

    natSubnet = mkOption {
      type = types.str;
      default = "192.168.255.0/24";
      description = "WireGuard subnet to NAT";
    };

    roaming = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            localEndpoint = mkOption {
              type = types.str;
              description = "Endpoint to use when on local network e.g., 10.10.10.1:51820";
            };
            remoteEndpoint = mkOption {
              type = types.str;
              description = "Endpoint to use when away e.g., home.mitchty.net:51820";
            };
            detectNetwork = mkOption {
              type = types.str;
              description = "IP or network to ping/check to detect if we're local ex 10.10.10.1";
            };
            peerPublicKey = mkOption {
              type = types.str;
              description = "Public key of the peer whose endpoint we're switching";
            };
          };
        }
      );
      default = null;
      # This craps not well tested/thought through tbh
      description = "Roaming client configuration - dynamically switch endpoint based on network location";
    };
  };

  config = mkIf cfg.enable (
    let
      hostname = config.networking.hostName;

      actualPrivateKeyFile = config.age.secrets.${cfg.privateKeyFile}.path;
    in
    {
      # Declare the age secret for the private key for host runtime decryption
      age.secrets.${cfg.privateKeyFile} = {
        file = ../../secrets/wireguard/prv + "/${hostname}.age";
        owner = "root";
        mode = "0400";
      };
    }
    // (
      let
        # Build the postUp script with nat if that kinda tings wanted
        fullPostUp =
          cfg.postSetup
          + optionalString cfg.enableNat ''
            # Enable NAT and forwarding for WireGuard clients to access the network
            ${pkgs.nftables}/bin/nft add table inet wireguard 2>/dev/null || true
            ${pkgs.nftables}/bin/nft add chain inet wireguard forward '{ type filter hook forward priority 0; policy accept; }' 2>/dev/null || true
            ${pkgs.nftables}/bin/nft add chain inet wireguard postrouting '{ type nat hook postrouting priority 100; policy accept; }' 2>/dev/null || true
            # Allow forwarding in and out of WireGuard interface
            ${pkgs.nftables}/bin/nft add rule inet wireguard forward iifname ${cfg.interface} accept
            ${pkgs.nftables}/bin/nft add rule inet wireguard forward oifname ${cfg.interface} accept
            # NAT traffic from WireGuard to LAN
            ${pkgs.nftables}/bin/nft add rule inet wireguard postrouting ip saddr ${cfg.natSubnet} oifname ${cfg.natInterface} masquerade
            # Allow WireGuard peer-to-peer forwarding (hub-and-spoke routing)
            ${pkgs.nftables}/bin/nft add rule inet wireguard forward iifname ${cfg.interface} oifname ${cfg.interface} accept
          '';

        # Build the preDown script too to delete all the wireguard crap
        fullPreDown =
          cfg.preShutdown
          + optionalString cfg.enableNat ''
            ${pkgs.nftables}/bin/nft delete table inet wireguard 2>/dev/null || true
          '';
      in
      {
        networking = {
          wireguard.enable = true;

          wg-quick.interfaces.${cfg.interface} = {
            inherit (cfg) address dns;
            privateKeyFile = actualPrivateKeyFile;
            postUp = fullPostUp;
            preDown = fullPreDown;

            listenPort = mkIf (cfg.listenPort != null) cfg.listenPort;

            peers = map (peer: {
              inherit (peer) publicKey allowedIPs;
              endpoint = mkIf (peer.endpoint != null) peer.endpoint;
              persistentKeepalive = mkIf (peer.persistentKeepalive != null) peer.persistentKeepalive;
            }) cfg.peers;
          };

          firewall = {
            # Allow WireGuard traffic on the interface, should I just enable this
            # on every interface? I mean even the gateway basically listens
            # everywhere? Tbh I'm tapped out braining for now whatever it works.
            trustedInterfaces = [ cfg.interface ];

            # Open the listening port for servers
            allowedUDPPorts = mkIf (cfg.listenPort != null) [ cfg.listenPort ];
          };
        };

        # TODO: This stuff needs to be tested yet
        # Roaming endpoint switcher for mobile clients
        # systemd.services."wireguard-roaming-${cfg.interface}" = mkIf (cfg.roaming != null) {
        #   description = "WireGuard roaming endpoint switcher for ${cfg.interface}";
        #   after = [ "wg-quick-${cfg.interface}.service" ];
        #   wants = [ "wg-quick-${cfg.interface}.service" ];
        #   wantedBy = [ "multi-user.target" ];

        #   # Restart whenever network state changes
        #   bindsTo = [ "network-online.target" ];

        #   serviceConfig = {
        #     Type = "oneshot";
        #     RemainAfterExit = false;
        #   };

        #   script = ''
        #     # Wait for interface to be up first
        #     while ! ${pkgs.wireguard-tools}/bin/wg show ${cfg.interface} > /dev/null 2>&1; do
        #       sleep 1
        #     done

        #     # Check if we can reach the local network or not...
        #     if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${cfg.roaming.detectNetwork} > /dev/null 2>&1; then
        #       echo "On local network, using local endpoint: ${cfg.roaming.localEndpoint}"
        #       ${pkgs.wireguard-tools}/bin/wg set ${cfg.interface} peer ${cfg.roaming.peerPublicKey} endpoint ${cfg.roaming.localEndpoint}
        #     else
        #       echo "Away from local network, using remote endpoint: ${cfg.roaming.remoteEndpoint}"
        #       ${pkgs.wireguard-tools}/bin/wg set ${cfg.interface} peer ${cfg.roaming.peerPublicKey} endpoint ${cfg.roaming.remoteEndpoint}
        #     fi
        #   '';
        # };

        # Timer to periodically check and update endpoint
        # systemd.timers."wireguard-roaming-${cfg.interface}" = mkIf (cfg.roaming != null) {
        #   description = "Periodic check for WireGuard roaming endpoint";
        #   wantedBy = [ "timers.target" ];
        #   timerConfig = {
        #     OnBootSec = "30s";
        #     OnUnitActiveSec = "60s";
        #   };
        # };
      }
    )
  );
}
