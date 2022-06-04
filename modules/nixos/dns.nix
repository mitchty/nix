{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.dns;
  # Conform to https://datatracker.ietf.org/doc/html/rfc8375 and use home.arpa for local dns
  homedomain = "home.arpa";
  extrahosts = (pkgs.writeText "dns-hosts" ''
    10.10.10.2 nexus.home.arpa nexus
    10.10.10.3 dfs1.home.arpa dfs1
    10.10.10.10 pikvm.home.arpa pikvm
    10.10.10.20 mb.home.arpa mb
    10.10.10.111 workmb.home.arpa workmb
  '');
in
{
  options.services.role.dns = {
    enable = mkEnableOption "Run unbound dns";
    serveLocalZones = mkEnableOption "Serve local zone files";
  };

  config = mkIf cfg.enable {
    networking.resolvconf = {
      useLocalResolver = false;
      extraConfig = "name_servers=10.10.10.2;";
    };
    systemd.services.dnsmasq = {
      path = [ pkgs.dnsmasq pkgs.bash pkgs.curl ];
    };
    services.dnsmasq = {
      enable = true;
      servers = [ "1.1.1.1" "8.8.8.8" ];
      extraConfig = ''
        # Setup what domain we're serving home.arpa basically for internal according to the rfc
        local=/${homedomain}/
        domain=${homedomain}

        # Don't need to cache negative entries
        no-negcache

        # Require a domain for stuff
        domain-needed

        # Forgot...
        bogus-priv

        # For below so we can do dig name and let it resolve to host.home.apa
        expand-hosts
        addn-hosts=${extrahosts}

        # Define our range for dhcp
        interface=eno1
        dhcp-range=eno1,10.10.10.10,10.10.10.127,24h

        # interface=wg0

        # Where we listen TODO: brain on this a bit
        listen-address=127.0.0.1,10.10.10.2

        bind-interfaces

        # Set default gateway
        dhcp-option=eno1,3,10.10.10.1

        # Set DNS server
        dhcp-option=eno1,6,10.10.10.2,1.1.1.1

        # For future
        # dhcp-boot=pxelinux.0
        # enable-tftp
        # tftp-root=/some/tftpboot/

        # And hosts, TODO is define this in nix and build this crap up
        # dynamically with extra hosts for now whatever future me problem
        dhcp-host=00:1f:c6:9b:9f:93,nexus,10.10.10.2
        dhcp-host=00:e2:69:15:7c:ea,dfs1,10.10.10.3

        dhcp-host=dc:a6:32:e9:42:f7,pikvm,10.10.10.10

        dhcp-host=a0:ce:c8:ce:43:48,mb,10.10.10.20

        dhcp-host=88:66:5a:56:92:d6,workmb,10.10.10.111

        # Also setup the dns blacklist
        conf-file=${inputs.dnsblacklist}/dnsmasq/dnsmasq.blacklist.txt
      '';
    };
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 67 68 69 ];
  };
}
