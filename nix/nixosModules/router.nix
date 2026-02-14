{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.router;

  extrahosts = (
    pkgs.writeText "dns-hosts" ''
      10.10.10.1 gw0.home.arpa gw0

      10.10.10.9 s1.home.arpa s1

      10.10.10.10 pikvm.home.arpa pikvm
      10.10.10.11 rtx.home.arpa rtx
      10.10.10.13 pikvm2.home.arpa pikvm2
      10.10.10.14 plx.home.arpa plx
      10.10.10.15 tmp.home.arpa tmp

      10.10.10.20 mb.home.arpa mb
      10.10.10.21 wm2.home.arpa wm2
      10.10.10.22 mbp.home.arpa mbp

      # WireGuard VPN addresses
      192.168.255.1 gw0.wg.home.arpa gw0.wg
      192.168.255.2 wm2.wg.home.arpa wm2.wg
      192.168.255.3 plx.wg.home.arpa plx.wg
      192.168.255.4 ark.wg.home.arpa ark.wg
      192.168.255.5 rtx.wg.home.arpa rtx.wg
      192.168.255.6 mbp.wg.home.arpa mbp.wg
      192.168.255.7 ip.wg.home.arpa ip.wg

      10.10.10.50 winfx.home.arpa winfx

      10.10.10.90 wwin.home.arpa wwin
      10.10.10.91 h1.home.arpa h1

      # Static ip's take up the last /16
      10.10.10.128 loki.home.arpa loki
      10.10.10.129 grafana.home.arpa grafana
      10.10.10.130 prometheus.home.arpa prometheus
      10.10.10.132 media.home.arpa media
      10.10.10.133 plex.home.arpa plex
      10.10.10.135 atuin.home.arpa atuin

      # Reverse proxy caches
      10.10.10.140 nix.cache.home.arpa oci.cache.home.arpa

      # "smart" bullshit
      10.10.10.180 spkitchen.home.arpa spkitchen

      # ha cluster ip address(es)
      10.10.10.200 cluster.home.arpa cluster
      10.10.10.201 cache.cluster.home.arpa
      10.10.10.202 nas.cluster.home.arpa

      # Edge test
      10.10.10.230 edge.home.arpa edge
      10.10.10.231 edge-rancher.home.arpa edge-rancher

      # Rando services
      10.10.10.220 ollama.home.arpa ollama
      10.10.10.221 open-webui.home.arpa open-webui
      10.10.10.222 slow-ollama.home.arpa ollama
      10.10.10.223 slow-open-webui.home.arpa open-webui
      10.10.10.224 karakeep.home.arpa karakeep
      10.10.10.225 homer.home.arpa homer
      10.10.10.226 llama.home.arpa llama
      10.10.10.227 git.home.arpa git

      # bridge stuff
      10.10.10.230 rancher.home.arpa rancher

      10.10.10.242 ark-nas.home.arpa

      # Wiffy ap's
      10.10.10.243 wifi.home.arpa wifi
      10.10.10.245 wifi2.home.arpa wifi2
      10.10.10.247 wifi3.home.arpa wifi3

      # Coredns for this subdomain/zone
      10.10.10.251 dev.home.arpa

      # This is for ark.home.arpa, its a 10 gig dac to the switch, using this to route traffic to/from the nas through this ip.
      10.10.10.252 ark-nas.home.arpa ark-nas
      10.10.10.253 ark.home.arpa ark
      # For testing dns works or not
      10.10.10.254 canary.home.arpa canary
    ''
  );
  dhcpHosts = [
    "58:47:ca:7c:08:77,ark-nas,10.10.10.242" # 10g dac used to route straight to the nas to offload the inbound ethernet port traffic, speeds up a lot of things.
    "90:09:d0:61:61:6a,s1,10.10.10.9"
    "e4:5f:01:92:cc:1f,pikvm,10.10.10.10"
    "e4:5f:01:b5:38:d2,pikvm2,10.10.10.13"
    "58:47:ca:7b:13:c4,plx,10.10.10.14" # s100 plex client
    "00:e2:69:a3:9f:ca,tmp,10.10.10.15"
    "f0:18:98:0d:0e:64,mb,10.10.10.20"
    "68:7a:64:48:f5:ad,wm2,10.10.10.21"
    "84:2f:57:60:af:6e,mbp,10.10.10.22"
    "3e:34:2b:0d:97:bc,iphone"
    "16:25:9d:16:af:ba,ipad"
    "c0:74:ad:f6:ba:54,wifi,10.10.10.248"
    "c0:74:ad:f6:c0:90,wifi2,10.10.10.249"
    "c0:74:ad:fc:45:58,wifi3,10.10.10.250"
    "c0:a5:e8:c0:28:df,wwin,10.10.10.90" # work win laptop
    "1e:19:04:4a:94:4c,h1,10.10.10.91"
    "dc:45:46:b3:5a:6a,winfx,10.10.10.50" # s100 win fx client
    "c4:e7:ae:0f:0c:2c,spkitchen,10.10.10.180"
    "c0:ff:ee:ee:ff:0c,edge,10.10.10.231"
  ];
  upstreamdns = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  # TODO: keep?
  localblacklist = (pkgs.writeText "localblocks" "");

  # CoreDNS configuration files
  corednsCorefile = pkgs.writeText "Corefile" ''
    dev.home.arpa:53 {
        bind 10.10.10.251

        # etcd backend for external-dns dynamic updates
        # Uses localhost since CoreDNS runs on same host as etcd
        etcd {
            path /skydns
            endpoint http://127.0.0.1:2379
        }

        # Fallback to static file for base records (ns1, etc)
        # With fallthrough so etcd can answer if file doesn't have the record
        file /var/lib/coredns/zones/dev.home.arpa.zone {
            fallthrough
        }

        transfer {
            to *
        }
        reload

        log {
            class all
        }
        errors
    }
  '';

  corednsZoneTemplate = pkgs.writeText "dev.home.arpa.zone.template" ''
    $ORIGIN dev.home.arpa.
    $TTL 300

    @   IN SOA ns1.dev.home.arpa. hostmaster.dev.home.arpa. (
            SERIAL_PLACEHOLDER ; serial
            7200       ; refresh (2 hours)
            3600       ; retry (1 hour)
            1209600    ; expire (2 weeks)
            300        ; minimum (5 minutes)
    )

    @   IN NS ns1.dev.home.arpa.
    ns1 IN A  10.10.10.251

    ; Dynamic entries will be added here by external-dns or other tools
    ; Allowed IP range: 10.10.10.144-159 (10.10.10.150/28)
    ; Example entries (remove or modify as needed):
    ; test IN A 10.10.10.150
  '';
in
{
  options.services.mitchty.router = {
    enable = mkEnableOption "Setup as my router/gateway host";
    blocklist = mkOption {
      type = types.str;
      default = "";
      description = "Whether to include a dns blacklist or not in dnsmasq and firewall, if not null is the file to use as a host blacklist";
    };
    domain = mkOption {
      type = types.str;
      default = "home.arpa";
      description = "Internal dns domain to use";
    };
    wanIp = mkOption {
      type = types.str;
      default = "10.10.10.1";
      description = "Ip address that defines the router as a gateway";
    };
    wanIface = mkOption {
      type = types.str;
      default = "";
      description = "interface (wan)";
    };
    lanIface = mkOption {
      type = types.str;
      default = "";
      description = "interface (lan)";
    };
    # wlanIface = mkOption {
    #   type = types.str;
    #   default = "wlp0s21f0u2";
    #   description = "interface (wlan)";
    # };
    dnsUpdate = {
      enable = mkEnableOption "Cloudflare DNS updates for WAN IP";
      record = mkOption {
        type = types.str;
        default = "";
        description = "DNS record to update (e.g., home.mitchty.net)";
      };
      interval = mkOption {
        type = types.str;
        default = "15min";
        description = "How often to check and update DNS (systemd time format)";
      };
      pkg = mkOption {
        type = types.package;
        description = "Package containing dns-update binary";
        default = pkgs.cf-dns-update;
      };
    };
  };

  config = mkIf cfg.enable {
    boot = {
      kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;

        # Disable these globally for now
        "net.ipv6.conf.all.use_tempaddr" = 1;

        # If we don't disable forwarding for the wan interface, for some reason
        # the router advertisements in ipv6 don't work. Linux is effing dumb.
        "net.ipv6.conf.br0.forwarding" = 1;
        "net.ipv6.conf.br0.accept_ra" = 1;

        "net.ipv6.conf.${cfg.wanIface}.accept_ra" = 1;
        "net.ipv6.conf.${cfg.wanIface}.accept_ra_mtu" = 0;
      };
    };

    networking = {
      # Only using dhcp for the wan interface
      useDHCP = false;

      resolvconf = {
        useLocalResolver = false;
      };

      # TODO: how can I swap this to ${cfg.routerIface}?
      # Use internal dnsmasq by default, has all the dns blacklists and stuff,
      # should be the fastest as well as its local network.
      #
      # But probably best to just leave it as is.
      nameservers = [ "127.0.0.1" ] ++ upstreamdns;

      bridges.br0.interfaces = [
        "enp5s0"
        "enp6s0"
        "enp7s0"
      ];

      interfaces = {
        "${cfg.wanIface}" = {
          useDHCP = true;
          #          macAddress = "9c:c9:fc:0c:8f:2e";
        };

        # br0 is basically "just" the switch+wireless nic
        # TODO: Future me maybe throw in vlans and setup more security
        enp5s0.useDHCP = false;
        enp6s0.useDHCP = false;
        enp7s0.useDHCP = false;

        br0 = {
          ipv4.addresses = [
            {
              address = "10.10.10.1";
              prefixLength = 24;
            }
            {
              address = "10.10.10.2";
              prefixLength = 24;
            }
            {
              address = "10.10.10.251";
              prefixLength = 24;
            }
            {
              address = "192.168.0.1";
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

      # We're only using dhcpcd for the wan interface eno1 to comcast
      #
      # There is a bunch of not interesting history behind all this setup. Most
      # of it is gleaned from painful tcpdump debugging for ipv6 because comcast
      # seems to goddamn love changing their ipv6 setup dam near every other
      # year or more.
      #
      # Partial history of this config (roughly):
      #
      # For god knows why I seem to now only be able to get a /64 and can't prefix delegate? wtf
      #
      # Comcast seems to be advertising an mtu of 9192 for god knows why, seems
      # like their internal network jumbo frame config is leaking.
      #Sep 17 19:57:54 gw0 dhcpcd[1196]: enp4s0: advertised MTU 9192 is greater than link MTU 1500
      #
      # Comcast also at some point seems to only allow me to request a prefix of
      # /60 at most vs even a /56 like you'd expect or the old /48. Stop
      # changing prefix delegation already.
      #
      # I also can't seem to request a prefix lower than 3 where I'm at, god knows why.
      dhcpcd = {
        allowInterfaces = [ "${cfg.wanIface}" ];
        denyInterfaces = [ "${cfg.lanIface}" ];
        IPv6rs = true;
        extraConfig = ''
          debug
          duid
          noarp

          interface ${cfg.wanIface}
          nohook mtu

          ipv4
          ipv6

          ia_na 0
          ia_pd 0/::64 ${cfg.lanIface}/3/96
        '';
      };

      enableIPv6 = true;

      nftables =
        let
          # This is a huge hack and not sure I want to keep it this way as a
          # flake input or not but... it works.... so whatever.
          #
          # No more mass spam from Brazil, China, and Russia (amongst other
          # countries) trying to probe my home ips.
          #
          # Its an improvement at least, way less dum spam in firewall logs, and
          # if I need to go abroad I can expand this to a proper module that
          # accepts country names as a list to allow. 99% of the time it'll be
          # us only tho so future mitch problem.
          ip4Allow = "${inputs.geo}/country/us/ipv4-aggregated.txt";
          ip6Allow = "${inputs.geo}/country/us/ipv6-aggregated.txt";

          rawCidrs = file: lib.splitString "\n" (builtins.readFile file);
          cidrs = file: lib.filter (line: line != "" && !(lib.hasPrefix "#" line)) (rawCidrs file);

          # Allow all private range ip traffic
          rfc1918 = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];

          ip4Cidrs = (cidrs ip4Allow) ++ rfc1918;
          ip6Cidrs = cidrs ip6Allow;

          mkSet = name: typ: elems: ''
            set ${name} {
              type ${typ}
              flags interval
              elements = { ${lib.concatStringsSep ", " elems} }
            }
          '';
        in
        {
          enable = true;
          ruleset = ''
            table inet filter {
              # Geo allow only asn's from the usa, other countries can't initiate any connections to local
              ${mkSet "asn_allow_v4" "ipv4_addr" ip4Cidrs}
              ${mkSet "asn_allow_v6" "ipv6_addr" ip6Cidrs}

              chain input {
                type filter hook input priority 0;

                iifname lo accept comment "lo in"

                ct state { established, related } counter accept comment "established in"

                iifname "br0" ether type arp counter accept comment "arp in"
                iifname "br0" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "allow limited ICMP"

                ip6 saddr fe80::/64 udp dport dhcpv6-client meta nftrace set 1 accept comment "ip6 dhcpv6 link-local in"

                ip6 nexthdr icmpv6 meta nftrace set 1 accept comment "ip6 icmp in"

                ip6 nexthdr icmpv6 icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } nftrace set 1  accept comment "ip6 nd in"

                # Allow ESP (IPv4/IPv6, since table inet)
                meta l4proto esp meta nftrace set 1 accept comment "ip4/6 esp in"

                ip saddr @asn_allow_v4 accept
                ip6 saddr @asn_allow_v6 accept
              }

              chain output {
                type filter hook output priority 0;

                # Allow outbound IPv6 ICMP
                ip6 nexthdr icmpv6 meta nftrace set 1 accept comment "ip6 icmp out"
              }

              chain forward {
                type filter hook forward priority 0;

                # Allow forwarded IPv6 ICMP
                ip6 nexthdr icmpv6 meta nftrace set 1 accept comment "ip6 icmp forward"
              }
            }
          '';
        };

      firewall = {
        enable = true;
        allowPing = true;

        allowedTCPPorts = [
          443
          8085
        ];
        allowedUDPPorts = [
          546
          547
          4500
          51820
        ];

        trustedInterfaces = [ cfg.lanIface ];

        interfaces = {
          "${cfg.wanIface}" = {
            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [
              546
              547
              51820
            ];
          };
          "${cfg.lanIface}" = {
            allowedTCPPorts = [
              53
              2379
            ];
            allowedUDPPorts = [ 53 ];
          };
        };
      };
    };
    services = {
      vnstat = {
        enable = true;
      };
      fail2ban = {
        enable = true;
        bantime-increment = {
          enable = true;
          rndtime = "7m";
          multipliers = "3 7 13 21";
          maxtime = "24h";
        };
        maxretry = 7;

        ignoreIP = [
          "127.0.0.1/8"
          "::1"
          "192.168.1.0/24"
          "10.10.10/24"
        ];
      };

      # etcd for CoreDNS backend (used by external-dns)
      etcd = {
        enable = true;
        name = "gw0"; # Must match the name in initialCluster
        # Listen on both localhost and the dev.home.arpa IP so external-dns can reach it
        listenClientUrls = [
          "http://127.0.0.1:2379"
          "http://10.10.10.251:2379"
        ];
        advertiseClientUrls = [ "http://10.10.10.251:2379" ];
        # Single node cluster for this use case
        initialCluster = [ "gw0=http://127.0.0.1:2380" ];
        initialAdvertisePeerUrls = [ "http://127.0.0.1:2380" ];
        listenPeerUrls = [ "http://127.0.0.1:2380" ];
      };
    };

    # CoreDNS for dev.home.arpa zone mostly here for k8s external dns
    environment.systemPackages = [ pkgs.coredns ];

    users.users.coredns = {
      isSystemUser = true;
      group = "coredns";
      description = "CoreDNS service user";
    };
    users.groups.coredns = { };

    age.secrets."dns-${cfg.dnsUpdate.record}" = mkIf cfg.dnsUpdate.enable {
      file = ../../secrets/dns + "/${cfg.dnsUpdate.record}.age";
      owner = "root";
      mode = "0400";
    };

    systemd = {
      services = {
        dnsmasq = {
          path = (
            lib.attrVals [
              "dnsmasq"
              "bash"
              "curl"
            ] pkgs
          );
        };
        # ncps = {
        #   # Getting failures from this for some reason
        #   preStart = lib.mkForce '''';
        # };

        coredns =
          let
            corednsPath = "/var/lib/coredns";
          in
          {
            description = "CoreDNS authoritative DNS for dev.home.arpa";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "sys-subsystem-net-devices-br0.device"
              "etcd.service"
            ];
            wants = [
              "network-online.target"
              "etcd.service"
            ];
            before = [ "dnsmasq.service" ];

            preStart = ''
              mkdir -p ${corednsPath}/zones

              cp ${corednsCorefile} ${corednsPath}/Corefile
              chmod 644 ${corednsPath}/Corefile

              if [ ! -f ${corednsPath}/zones/dev.home.arpa.zone ]; then
                SERIAL=$(date +%Y%m%d01)
                sed "s/SERIAL_PLACEHOLDER/$SERIAL/" ${corednsZoneTemplate} > ${corednsPath}/zones/dev.home.arpa.zone
                chmod 644 ${corednsPath}/zones/dev.home.arpa.zone
              fi

              chmod 755 ${corednsPath}/zones
            '';

            serviceConfig = {
              Type = "simple";
              ExecStart = "${pkgs.coredns}/bin/coredns -conf ${corednsPath}/Corefile";
              ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
              User = "coredns";
              Group = "coredns";
              Restart = "always";
              RestartSec = "5s";

              # Systemd owns /var/lib/coredns
              StateDirectory = "coredns";
              StateDirectoryMode = "0755";

              # Prevent systemd from killing the service generally? Needed anymore I was testing? FUTURE MITCH PROBLEM
              SendSIGKILL = false;

              # Let this bind() to port 53 as non root
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
              CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

              # Same here might not be needed, hell might break updates dunno...
              StopWhenUnneeded = false;
            };
          };
        cloudflare-dns-update = mkIf cfg.dnsUpdate.enable {
          description = "Update Cloudflare DNS record with current WAN IP";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.age.secrets."dns-${cfg.dnsUpdate.record}".path;
            ExecStart = pkgs.writeShellScript "cloudflare-dns-update" ''
              set -euo pipefail

              # FUTURE MITCH TODO: better way to get the ip for the wan interface
              IP=$(${pkgs.iproute2}/bin/ip -br addr show ${cfg.wanIface} | ${pkgs.gawk}/bin/awk '{print $3}' | ${pkgs.gnused}/bin/sed -e 's|/.*||g')

              if [ -z "$IP" ]; then
                printf "fatal: didn't get an ip for %s\n" "${cfg.wanIface}" >&2
                exit 1
              fi

              ${cfg.dnsUpdate.pkg}/bin/dns-update --record ${cfg.dnsUpdate.record} --ip "$IP"
            '';
          };
        };
      };
      timers.cloudflare-dns-update = mkIf cfg.dnsUpdate.enable {
        description = "Timer for periodic Cloudflare DNS updates";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.dnsUpdate.interval;
          Unit = "cloudflare-dns-update.service";
        };
      };
    };

    services.radvd = {
      enable = true;
      config = ''
        interface br0 {
        AdvSendAdvert on;
        AdvHomeAgentFlag off;
        MinRtrAdvInterval 30;
        MaxRtrAdvInterval 100;
        AdvDefaultPreference high;
        prefix ::/64 {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
        };
        };
      '';
    };

    #    systemd.services.dnsmasq.requires = [ "br0-netdev.service" ];

    services.dnsmasq = {
      enable = true;
      settings = {
        server = upstreamdns ++ [ "/dev.home.arpa/10.10.10.251" ];
        clear-on-reload = true;
        log-dhcp = true;
        local = "/${cfg.domain}/";
        inherit (cfg) domain;
        no-negcache = true;
        domain-needed = true;
        bogus-priv = true;
        no-hosts = true;
        addn-hosts = "${extrahosts}";
        # Bind only to specific addresses for DNS
        bind-interfaces = true;
        enable-ra = true;
        listen-address = "127.0.0.1,${cfg.wanIp}";
        # Don't use global interface - DHCP range already specifies the interface
        dhcp-range = [
          "${cfg.lanIface},10.10.10.3,10.10.10.127,24h"
          "tag:${cfg.wanIface},::1,constructor:${cfg.wanIface},ra-names,1h"
        ];
        dhcp-option = [
          "${cfg.lanIface},3,${cfg.wanIp}"
          "${cfg.lanIface},6,${cfg.wanIp}"
        ];
        dhcp-host = dhcpHosts;
        conf-file = "${inputs.dns}/dnsmasq/pro.plus.txt";
      };
    };
  };
}
