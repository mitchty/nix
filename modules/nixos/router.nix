{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.router;

  #
  ip4 = rec {
    ip = a: b: c: d: prefixLength: {
      inherit a b c d prefixLength;
      address = "${toString a}.${toString b}.${toString c}.${toString d}";
    };

    toCIDR = addr: "${addr.address}/${toString addr.prefixLength}";
    toNetworkAddress = addr: with addr; { inherit address prefixLength; };
    toNumber = addr: with addr; a * 16777216 + b * 65536 + c * 256 + d;
    fromNumber = addr: prefixLength:
      let
        aBlock = a * 16777216;
        bBlock = b * 65536;
        cBlock = c * 256;
        a = addr / 16777216;
        b = (addr - aBlock) / 65536;
        c = (addr - aBlock - bBlock) / 256;
        d = addr - aBlock - bBlock - cBlock;
      in
      ip a b c d prefixLength;

    fromString = with lib; str:
      let
        splits1 = splitString "." str;
        splits2 = flatten (map (x: splitString "/" x) splits1);

        e = i: toInt (builtins.elemAt splits2 i);
      in
      ip (e 0) (e 1) (e 2) (e 3) (e 4);

    fromIPString = str: prefixLength:
      fromString "${str}/${toString prefixLength}";

    network = addr:
      let
        pfl = addr.prefixLength;
        pow = n: i:
          if i == 1 then
            n
          else
            if i == 0 then
              1
            else
              n * pow n (i - 1);

        shiftAmount = pow 2 (32 - pfl);
      in
      fromNumber ((toNumber addr) / shiftAmount * shiftAmount) pfl;
  };

  # Static ip junk
  loki = "10.10.10.128";

  extrahosts = (pkgs.writeText "dns-hosts" ''
    10.10.10.1 gw.home.arpa gw
    10.10.10.3 nexus.home.arpa nexus
    10.10.10.4 dfs1.home.arpa dfs1
    10.10.10.5 srv.home.arpa srv
    10.10.10.6 cl1.home.arpa cl1
    10.10.10.7 cl2.home.arpa cl2

    10.10.10.10 pikvm.home.arpa pikvm
    10.10.10.20 mb.home.arpa mb
    10.10.10.30 iphone.home.arpa iphone
    10.10.10.31 ipad.home.arpa ipad

    10.10.10.99 wmb.home.arpa wmb

    10.10.10.127 wifi.home.arpa wifi

    # Static ip's take up the last /16
    10.10.10.128 loki.home.arpa loki
    10.10.10.129 grafana.home.arpa grafana
    10.10.10.130 prometheus.home.arpa prometheus
    10.10.10.131 nixcache.home.arpa nixcache

    # For testing dns works or not
    10.10.10.254 canary.home.arpa canary
  '');
  upstreamdns = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  # Note for work vpn need to setup the firewall rules as per:
  # https://www.arubanetworks.com/techdocs/VIA/4x/Content/VIA%20Config/Before_you_Begin.htm
  #
  # Bit of a hack I think due to this issue https://github.com/NixOS/nixpkgs/issues/69265
  workvpnadd = ''
    ${pkgs.iptables}/bin/iptables --insert INPUT --protocol ESP --jump ACCEPT
  '';
  workvpnrm = ''
    ${pkgs.iptables}/bin/iptables --delete INPUT --protocol ESP --jump ACCEPT
  '';
in
{
  options.services.role.router = {
    enable = mkEnableOption "Setup as a router/gateway host";
    blacklist = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to include a dns blacklist or not in dnsmasq and firewall";
    };
    domain = mkOption {
      type = types.str;
      default = "home.arpa";
      description = "Internal dns domain to use";
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

  config = mkIf cfg.enable rec {
    boot = {
      kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;

        # Disable these globally
        "net.ipv6.conf.all.use_tempaddr" = 1;

        # If we don't disable forwarding for the wan interface, for some reason
        # the router advertisements in ipv6 don't work. Linux is effing dumb.
        "net.ipv6.conf.br0.forwarding" = 1;
        "net.ipv6.conf.br0.accept_ra" = 1;
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

      # We're only using dhcpcd for the wan interface eno1
      dhcpcd.extraConfig = ''
        duid

        slaac private

        allowinterfaces ${cfg.wanIface}
        denyinterfaces ${cfg.lanIface}

        interface ${cfg.wanIface}
        ipv6rs
        ipv4
        ipv6
        ia_na 0

        # Why the hell prefix delegation only seems to work with prefix 3 is
        # beyond me. Comcast ipv6 is wack. Also why can I only get a delegation
        # of /60? Everything here determined through painful trial and error.
        ia_pd 0/::/60 ${cfg.lanIface}/3/64
      '';

      firewall = {
        enable = true;
        allowPing = true;
        # Needed for ipsec vpn traffic
        extraCommands = ''
          ${pkgs.iptables}/bin/ip6tables -A INPUT -p udp --dport dhcpv6-client -j nixos-fw-accept
          ${pkgs.iptables}/bin/ip6tables -A INPUT -p ipv6-icmp -j nixos-fw-accept
          ${pkgs.iptables}/bin/ip6tables -A OUTPUT -p ipv6-icmp -j nixos-fw-accept
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -p ipv6-icmp -j nixos-fw-accept
          ${pkgs.iptables}/bin/iptables --insert INPUT --protocol ESP --jump nixos-fw-accept
        '';
        # ^^^ needs to be idempotent so we need to delete anything added and
        # also handle if it may not exist.
        extraStopCommands = ''
          ${pkgs.iptables}/bin/ip6tables -D INPUT -p udp --dport dhcpv6-client -j nixos-fw-accept || :
          ${pkgs.iptables}/bin/ip6tables -D INPUT -p ipv6-icmp -j nixos-fw-accept || :
          ${pkgs.iptables}/bin/ip6tables -D OUTPUT -p ipv6-icmp -j nixos-fw-accept || :
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -p ipv6-icmp -j nixos-fw-accept || :
          ${pkgs.iptables}/bin/iptables --delete INPUT --protocol ESP --jump nixos-fw-accept || :
        '';

        allowedTCPPorts = [ 443 8085 ];
        allowedUDPPorts = [ 546 547 4500 ];

        trustedInterfaces = [ cfg.lanIface ];

        interfaces = {
          "${cfg.wanIface}" = {
            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [ 546 547 ];
          };
        };
      };
    };
    services.vnstat = {
      enable = true;
    };
    systemd.services.dnsmasq = {
      path = with pkgs; [
        dnsmasq
        bash
        curl
      ];
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
    services.dnsmasq = {
      enable = true;
      servers = upstreamdns;
      extraConfig = ''
        # I like logs, lets have more of em
        # log-queries
        log-dhcp

        # Setup what domain we're serving home.arpa basically for internal
        # according to the rfc
        local=/${cfg.domain}/
        domain=${cfg.domain}

        # Don't need to cache negative entries
        no-negcache

        # Require a domain for stuff
        domain-needed

        # Forgot...
        bogus-priv

        # expand-hosts will bring in crap like 127.0.0.2, I SAID NO, bad option
        # go home
        no-hosts

        # dns hosts
        addn-hosts=${extrahosts}

        # Define our range for dhcp
        interface=${cfg.lanIface}
        dhcp-range=${cfg.lanIface},10.10.10.3,10.10.10.127,24h

        # Create a IPv6 range from address on the interface. The ::1 is related to the ifid in /etc/wide-dhcpv6/dhcp6c.conf.
        # dhcp-range=tag:${cfg.lanIface},::1,constructor:${cfg.lanIface}, ra-names, 12h
        dhcp-range=tag:${cfg.wanIface},::1,constructor:${cfg.wanIface}, ra-names, 12h

        # IPv6 Route Advertisements
        enable-ra

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
        dhcp-host=50:65:f3:6b:01:2a,srv,10.10.10.5

        # Storage nas cluster of whatever I throw on it
        dhcp-host=6c:bf:b5:02:a7:9d,cl1,10.10.10.6
        dhcp-host=6c:bf:b5:02:89:cf,cl2,10.10.10.7

        # pikvm is here now
        dhcp-host=e4:5f:01:92:cc:1f,pikvm,10.10.10.10

        # ether
        dhcp-host=a0:ce:c8:ce:43:48,mb,10.10.10.20
        # wifi
        # dhcp-host=f0:18:98:0d:0e:64,mb,10.10.10.20

        dhcp-host=3e:34:2b:0d:97:bc,iphone,10.10.10.30
        dhcp-host=c2:84:0f:47:5e:60,ipad,10.10.10.31

        dhcp-host=88:66:5a:56:92:d6,wmb,10.10.10.99

        dhcp-host=e8:48:b8:1d:b7:f1,wifi,10.10.10.127
      '' + optionalString (cfg.blacklist) ''

        # Also setup the dns blacklist if enabled
        conf-file=${inputs.dnsblacklist}/dnsmasq/dnsmasq.blacklist.txt
      '';
    };
  };
}
