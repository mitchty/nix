{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.router;
  homedomain = "home.arpa";
  extrahosts = (pkgs.writeText "dns-hosts" ''
    10.10.10.1 gw.home.arpa gw
    10.10.10.3 nexus.home.arpa nexus
    10.10.10.4 dfs1.home.arpa dfs1
    10.10.10.10 pikvm.home.arpa pikvm
    10.10.10.20 mb.home.arpa mb
    10.10.10.30 iphone.home.arpa iphone
    10.10.10.31 ipad.home.arpa ipad

    10.10.10.99 workmb.home.arpa workmb

    10.10.10.126 grafana.home.arpa grafana
    10.10.10.127 wifi.home.arpa wifi
  '');
  upstreamdns = [
    "1.1.1.1"
    "8.8.8.8"
  ];
in
{
  options.services.role.router = {
    enable = mkEnableOption "Setup as a router/gateway host";
    blacklist = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include a dns blacklist or not in dnsmasq and firewall";
    };
    routerIp = mkOption {
      type = types.str;
      default = "10.10.10.254";
      description = "router ip address";
    };
    wanIface = mkOption {
      type = types.str;
      default = "eno1";
      description = "interface (wan)";
    };
    lanIface = mkOption {
      type = types.str;
      default = "br0";
      description = "interface (lan)";
    };
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = mkForce true;

      "net.ipv6.conf.all.forwarding" = mkForce true;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;

      "net.ipv6.conf.eno1.accept_ra" = 2;
      "net.ipv6.conf.eno1.autoconf" = 1;
    };
    networking = {
      resolvconf = {
        useLocalResolver = false;
      };
      # TODO: how can I swap this to ${cfg.routerIface}?
      # Use internal dnsmasq by default, has all the dns blacklists and stuff,
      # should be the fastest as well as its local network.
      nameservers = [ "127.0.0.1" ] ++ upstreamdns;

      bridges.br0.interfaces = [ "enp2s0" "enp3s0" "enp6s0" ];

      interfaces = {
        eno1.useDHCP = true;

        # br0 is all these 3 devices
        enp2s0.useDHCP = false;
        enp3s0.useDHCP = false;
        enp6s0.useDHCP = false;

        br0 = {
          ipv4.addresses = [
            {
              address = "10.10.10.1";
              prefixLength = 24;
            }
            {
              address = "10.10.10.126";
              prefixLength = 24;
            }
          ];
        };
      };
      nat = {
        enable = true;
        internalInterfaces = [
          cfg.lanIface
        ];
        externalInterface = "${cfg.wanIface}";
      };
      firewall = {
        enable = true;
        trustedInterfaces = [ cfg.lanIface ];

        interfaces = {
          "${cfg.wanIface}" = {
            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [ ];
          };
          "${cfg.lanIface}" = {
            allowedTCPPorts = [ 80 ];
            allowedUDPPorts = [ ];
          };
        };
      };

    };
    systemd.services.dnsmasq = {
      path = with pkgs; [
        dnsmasq
        bash
        curl
      ];
    };
    services.dnsmasq = {
      enable = true;
      servers = upstreamdns;
      extraConfig = ''
        # I like logs, lets have more of em
        log-queries
        log-dhcp

        # Setup what domain we're serving home.arpa basically for internal according to the rfc
        local=/${homedomain}/
        domain=${homedomain}

        # Don't need to cache negative entries
        no-negcache

        # Require a domain for stuff
        domain-needed

        # Forgot...
        bogus-priv

        # expand-hosts will bring in crap like 127.0.0.2 for nexus, I SAID NO,
        # bad option go home
        no-hosts

        # dns hosts
        addn-hosts=${extrahosts}

        # Define our range for dhcp
        interface=${cfg.lanIface}
        dhcp-range=${cfg.lanIface},10.10.10.3,10.10.10.127,24h

        # interface=wg0

        # Where we listen TODO: brain on this a bit
        listen-address=127.0.0.1,10.10.10.1

        bind-interfaces

        # Set default gateway
        dhcp-option=${cfg.lanIface},3,10.10.10.1

        # Set DNS servers sent to dhcp hosts
        dhcp-option=${cfg.lanIface},6,10.10.10.1

        # For future
        # dhcp-boot=pxelinux.0
        # enable-tftp
        # tftp-root=/some/tftpboot/

        # And hosts, TODO is define this in nix and build this crap up
        # dynamically with extra hosts for now whatever future me problem
        dhcp-host=00:1f:c6:9b:9f:93,nexus,10.10.10.3
        dhcp-host=00:e2:69:15:7c:ea,dfs1,10.10.10.4

        dhcp-host=dc:a6:32:e9:42:f7,pikvm,10.10.10.10

        dhcp-host=a0:ce:c8:ce:43:48,mb,10.10.10.20

        dhcp-host=3e:34:2b:0d:97:bc,iphone,10.10.10.30
        dhcp-host=c2:84:0f:47:5e:60,ipad,10.10.10.31

        dhcp-host=88:66:5a:56:92:d6,workmb,10.10.10.99

        dhcp-host=e8:48:b8:1d:b7:f1,wifi,10.10.10.127
      '' + optionalString (cfg.blacklist) ''

        # Also setup the dns blacklist if enabled
        conf-file=${inputs.dnsblacklist}/dnsmasq/dnsmasq.blacklist.txt
      '';
    };
    # Lets try out graphana/prometheus to visualize junk
    services.grafana = {
      enable = true;
      domain = "grafana.home.arpa";
      port = 80;
      addr = "10.10.10.126";
    };
    services.prometheus = {
      enable = true;
      port = 9001;
      extraFlags = [ "--web.enable-admin-api" ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
      scrapeConfigs = [
        {
          job_name = "gw.home.arpa";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
      ];
    };
  };
}
