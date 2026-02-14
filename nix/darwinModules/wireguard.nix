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

    # I mostly copied the nixos module so server doesn't really make sense here but WHATEVER it keeps options in sync
    role = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      description = "Whether this host is a WireGuard server or client";
    };

    interface = mkOption {
      type = types.str;
      default = "utun99";
      description = "WireGuard interface name macos wg-quick normally picks this name randomly like a jerk so whatever this is used for crap like logfiles";
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
      description = "Port to listen on";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "DNS servers to use when connected";
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
              description = "Peer endpoint (host:port)";
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
      description = "Enable NAT/masquerading for WireGuard clients - server only";
    };

    natInterface = mkOption {
      type = types.str;
      default = "en0";
      description = "Interface to NAT WireGuard traffic to e.g., en0, en1";
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
              description = "IP or network to ping/check to detect if we're local (e.g., 10.10.10.1";
            };
            peerPublicKey = mkOption {
              type = types.str;
              description = "Public key of the peer whose endpoint we're switching";
            };
          };
        }
      );
      default = null;
      description = "Roaming client configuration - dynamically switch endpoint based on network location";
    };
  };

  config = mkIf cfg.enable (
    let
      hostname = config.networking.hostName;

      actualPrivateKeyFile = config.age.secrets.${cfg.privateKeyFile}.path;

      # Build PostUp script combining split DNS and custom postSetup, macos dns is easy peasy to setup as split dns
      postUpCommands =
        (optional (
          cfg.dns != [ ]
        ) "mkdir -p /etc/resolver && echo 'nameserver ${builtins.head cfg.dns}' > /etc/resolver/home.arpa")
        ++ (optional (cfg.dns != [ ]) "dscacheutil -flushcache")
        ++ (optional (cfg.dns != [ ]) "killall -HUP mDNSResponder")
        ++ (optional (cfg.postSetup != "") cfg.postSetup);

      postUpScript = optionalString (postUpCommands != [ ]) (concatStringsSep "; " postUpCommands);

      preDownCommands =
        (optional (cfg.dns != [ ]) "rm -f /etc/resolver/home.arpa")
        ++ (optional (cfg.preShutdown != "") cfg.preShutdown);

      preDownScript = optionalString (preDownCommands != [ ]) (concatStringsSep "; " preDownCommands);

      configFile = pkgs.writeText "wg-${cfg.interface}.conf" ''
        [Interface]
        PrivateKey = $(cat ${actualPrivateKeyFile})
        Address = ${concatStringsSep ", " cfg.address}
        ${optionalString (cfg.listenPort != null) "ListenPort = ${toString cfg.listenPort}"}

        ${optionalString (postUpScript != "") ''
          PostUp = ${postUpScript}
        ''}
        ${optionalString (preDownScript != "") ''
          PreDown = ${preDownScript}
        ''}

        ${concatMapStringsSep "\n" (peer: ''
          [Peer]
          PublicKey = ${peer.publicKey}
          AllowedIPs = ${concatStringsSep ", " peer.allowedIPs}
          ${optionalString (peer.endpoint != null) "Endpoint = ${peer.endpoint}"}
          ${optionalString (
            peer.persistentKeepalive != null
          ) "PersistentKeepalive = ${toString peer.persistentKeepalive}"}
        '') cfg.peers}
      '';

      # Script to bring up WireGuard
      wgUp = pkgs.writeShellScript "wg-${cfg.interface}-up" ''
        set -e
        export PATH="${pkgs.wireguard-tools}/bin:$PATH"

        # Create a temporary directory for the config
        config_dir=$(mktemp -d)
        trap "rm -rf $config_dir" EXIT

        # Generate the config with the actual private key
        # wg-quick uses the filename (without extension) as the interface name
        config_file="$config_dir/wg0.conf"
        cat ${configFile} | sed "s|\$(cat ${actualPrivateKeyFile})|$(cat ${actualPrivateKeyFile})|g" > "$config_file"

        # Bring up the interface
        ${pkgs.wireguard-tools}/bin/wg-quick up "$config_file"

        # Keep the script running so launchd doesn't restart too frequently
        # Sleep for 25s to align with WireGuard keepalive interval, I might need to tweak this needs more testing
        # Its working though so future me problem
        while true; do
          sleep 25 &
          wait $!
        done
      '';

      # TODO: use me at some point...
      wgDown = pkgs.writeShellScript "wg-${cfg.interface}-down" ''
        set -e
        export PATH="${pkgs.wireguard-tools}/bin:$PATH"

        # Find the utun interface by checking WireGuard interfaces
        iface=$(${pkgs.wireguard-tools}/bin/wg show interfaces | tr ' ' '\n' | grep -E '^utun[0-9]+$' | head -1 || true)

        if [ -n "$iface" ]; then
          ${pkgs.wireguard-tools}/bin/wg-quick down "$iface"
        fi
      '';

      # Roaming script, needs more testing and validation its not stupid wrong
      wgRoaming = pkgs.writeShellScript "wg-${cfg.interface}-roaming" ''
        set -e
        export PATH="${pkgs.wireguard-tools}/bin:${pkgs.netcat}/bin:$PATH"

        # Find the wireguard interface
        iface=$(${pkgs.wireguard-tools}/bin/wg show interfaces | tr ' ' '\n' | grep -E '^utun[0-9]+$' | head -1 || true)

        if [ -z "$iface" ]; then
          echo "WireGuard interface not found"
          exit 0
        fi

        # Check if we can reach the local network
        # if ping -c 1 -W 2 ${cfg.roaming.detectNetwork} > /dev/null 2>&1; then
        #   echo "On local network, using local endpoint: ${cfg.roaming.localEndpoint}"
        #   ${pkgs.wireguard-tools}/bin/wg set "$iface" peer ${cfg.roaming.peerPublicKey} endpoint ${cfg.roaming.localEndpoint}
        # else
          echo "Away from local network, using remote endpoint: ${cfg.roaming.remoteEndpoint}"
          ${pkgs.wireguard-tools}/bin/wg set "$iface" peer ${cfg.roaming.peerPublicKey} endpoint ${cfg.roaming.remoteEndpoint}
        # fi
      '';
    in
    {
      age.secrets.${cfg.privateKeyFile} = {
        file = ../../secrets/wireguard/prv + "/${hostname}.age";
        owner = "root";
        mode = "0400";
      };

      environment.systemPackages = [ pkgs.wireguard-tools ];

      # Create launchd service for WireGuard
      launchd.daemons."wireguard-${cfg.interface}" = {
        serviceConfig = {
          Label = "org.nixos.wireguard-${cfg.interface}";
          ProgramArguments = [ "${wgUp}" ];
          RunAtLoad = true;
          KeepAlive = {
            NetworkState = true;
          };
          StandardOutPath = "/var/log/wireguard-${cfg.interface}.log";
          StandardErrorPath = "/var/log/wireguard-${cfg.interface}.log";
        };
      };

      # Create launchd agent for roaming
      launchd.daemons."wireguard-roaming-${cfg.interface}" = mkIf (cfg.roaming != null) {
        serviceConfig = {
          Label = "org.nixos.wireguard-roaming-${cfg.interface}";
          ProgramArguments = [ "${wgRoaming}" ];
          StartInterval = 60; # Check every 60 seconds
          RunAtLoad = true;
          StandardOutPath = "/var/log/wireguard-roaming-${cfg.interface}.log";
          StandardErrorPath = "/var/log/wireguard-roaming-${cfg.interface}.log";
        };
      };
    }
  );
}
