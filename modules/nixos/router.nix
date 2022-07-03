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
  '');
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
      type = types.string;
      default = "10.10.10.254";
      description = "router ip address";
    };
    routerIface = mkOption {
      type = types.string;
      default = "eno1";
      description = "router interface (wan)";
    };
    lanIface = mkOption {
      type = types.string;
      default = "lan";
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
      nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];

      bridges.br0.interfaces = [ "enp2s0" "enp3s0" "enp6s0" ];

      interfaces = {
        # Don't request DHCP on wan interface yet
        # eno1 = {
        #   useDHCP = false;
        #   ipv4.addresses = [{ address = cfg.routerIp; prefixLength = 24; }];
        # };
        eno1.useDHCP = true;
        # This will be the "lan" interface
        enp2s0.useDHCP = false;
        enp3s0.useDHCP = false;
        enp6s0.useDHCP = false;

        br0 = {
          ipv4.addresses = [{
            address = "10.10.10.1";
            prefixLength = 24;
          }];
        };
      };

      # This system won't use the nixos firewall setup, we'll define nftable rules directly
      nat = {
        enable = true;
        internalInterfaces = [
          "br0"
        ];
        externalInterface = "eno1";
      };
      firewall = {
        enable = true;
        trustedInterfaces = [ "br0" ];

        interfaces = {
          eno1 = {
            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [ ];
          };
          # wguest = {
          #   allowedTCPPorts = [
          #     # DNS
          #     53
          #     # HTTP(S)
          #     80
          #     443
          #     110
          #     # Email (pop3, pop3s)
          #     995
          #     114
          #     # Email (imap, imaps)
          #     993
          #     # Email (SMTP Submission RFC 6409)
          #     587
          #     # Git
          #     2222
          #   ];
          #   allowedUDPPorts = [
          #     # https://serverfault.com/a/424226
          #     # DNS
          #     53
          #     # DHCP
          #     67
          #     68
          #     # NTP
          #     123
          #   ];
          # };
        };
      };

      # nftables = {
      #   enable = true;

      #   ruleset = ''
      #     table bridge filter {
      #       chain prerouting {
      #         type filter hook prerouting priority 0;
      #         policy accept;
      #       }
      #     	chain input {
      #     		type filter hook input priority 0; policy accept;
      #     		iifname "br0" accept
      #     	}
      #     	chain forward {
      #     		type filter hook forward priority 0; policy drop;
      #     		iifname "br0" accept
      #     	}
      #       chain drop_ra_dhcp {
      #         # Blocks: router advertisements, dhcpv6, dhcpv4
      #         icmpv6 type nd-router-advert drop
      #         ip6 version 6 udp sport 547 drop
      #         ip  version 4 udp sport 67 drop
      #       }
      #     }
      #     table ip filter {
      #     	# allow all packets sent by the firewall machine itself
      #     	chain output {
      #     		type filter hook output priority 100; policy accept;
      #     	}

      #     	# allow LAN to firewall, disallow WAN to firewall
      #     	chain input {
      #     		type filter hook input priority 0; policy accept;
      #     		iifname "br0" accept
      #     		iifname "eno1" drop
      #     	}

      #     	# allow packets from LAN to WAN, and WAN to LAN if LAN initiated the connection
      #     	chain forward {
      #     		type filter hook forward priority 0; policy drop;
      #     		iifname "br0" oifname "eno1" accept
      #     		iifname "eno1" oifname "br0" ct state related,established accept
      #     	}
      #     }
      #     table ip nat {
      #     	chain prerouting {
      #         type nat hook prerouting priority 0; policy accept;
      #         iifname "eno1" accept
      #       }

      #     	# for all packets to WAN, after routing, replace source address with primary IP of WAN interface
      #       chain postrouting {
      #       	type nat hook postrouting priority 100; policy accept;
      #         oifname "eno1" masquerade
      #       }
      #     }
      #     table inet filter {
      #     	chain input {
      #     		type filter hook input priority 0; policy drop;
      #     		ct state invalid counter drop comment "early drop of invalid packets"
      #     		ct state {established, related} counter accept comment "accept all connections related to connections made by us"
      #     		iif lo accept comment "accept loopback"
      #     		iif != lo ip daddr 127.0.0.1/8 counter drop comment "drop connections to loopback not coming from loopback"
      #     		iif != lo ip6 daddr ::1/128 counter drop comment "drop connections to loopback not coming from loopback"
      #     		ip protocol icmp counter accept comment "accept all ICMP types"
      #     		ip6 nexthdr icmpv6 counter accept comment "accept all ICMP types"
      #     		tcp dport 22 counter accept comment "accept SSH"
      #     		counter comment "count dropped packets"
      #     	}
      #       chain forward {
      #        	type filter hook forward priority 0; policy drop;
      #   	    counter comment "count dropped packets"
      #       }

      #       # If you're not counting packets, this chain can be omitted.
      #       chain output {
      #   	    type filter hook output priority 0; policy accept;
      #   	    counter comment "count accepted packets"
      #       }
      #     }
      #   '';
      # };
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
      servers = [ "1.1.1.1" "8.8.8.8" ];
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
        interface=br0
        dhcp-range=br0,10.10.10.3,10.10.10.127,1h

        # interface=wg0

        # Where we listen TODO: brain on this a bit
        listen-address=127.0.0.1,10.10.10.1

        bind-interfaces

        # Set default gateway
        dhcp-option=br0,3,10.10.10.1

        # Set DNS servers sent to dhcp hosts
        dhcp-option=br0,6,10.10.10.1

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
      '' + optionalString (cfg.blacklist) ''

        # Also setup the dns blacklist if enabled
        conf-file=${inputs.dnsblacklist}/dnsmasq/dnsmasq.blacklist.txt
      '';
    };
  };
}
