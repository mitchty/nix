{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.router;
  homedomain = "home.arpa";
  extrahosts = (pkgs.writeText "dns-hosts" ''
    10.10.10.1 gw.home.arpa gw
    10.10.10.3 nexus.home.arpa nexus
    10.10.10.4 dfs1.home.arpa dfs1
    10.10.10.5 srv.home.arpa srv
    10.10.10.10 pikvm.home.arpa pikvm
    10.10.10.20 mb.home.arpa mb
    10.10.10.30 iphone.home.arpa iphone
    10.10.10.31 ipad.home.arpa ipad

    10.10.10.99 wmb.home.arpa wmb

    10.10.10.125 loki.home.arpa loki
    10.10.10.126 grafana.home.arpa grafana
    10.10.10.127 wifi.home.arpa wifi

    10.10.10.254 canary.home.arpa canary
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
              address = "10.10.10.125";
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
            allowedTCPPorts = [
              80
              config.services.loki.configuration.server.http_listen_port
              # Seems to be some internal thing that loki spins up that it needs to connect to
              9095
            ];
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
        dhcp-host=50:65:f3:6b:01:2a,srv,10.10.10.5

        dhcp-host=dc:a6:32:e9:42:f7,pikvm,10.10.10.10

        dhcp-host=a0:ce:c8:ce:43:48,mb,10.10.10.20

        dhcp-host=3e:34:2b:0d:97:bc,iphone,10.10.10.30
        dhcp-host=c2:84:0f:47:5e:60,ipad,10.10.10.31

        dhcp-host=88:66:5a:56:92:d6,wmb,10.10.10.99

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
      analytics.reporting.enable = false;
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
          job_name = "nixos";
          static_configs = [{
            targets = [
              "gw.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "nexus.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "dfs1.home.arpa:${toString config.services.prometheus.exporters.node.port}"
              "srv.home.arpa:${toString config.services.prometheus.exporters.node.port}"
            ];
          }];
        }
        {
          job_name = "macos";
          static_configs = [{
            targets = [
              "mb.home.arpa:9100"
            ];
          }];
        }
      ];
    };
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3101;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://${toString config.services.loki.configuration.ingester.lifecycler.address}:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }];
        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
      };
    };
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = 3100;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "loki.home.arpa";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
          max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2022-06-06";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
            cache_ttl = "24h";
            shared_store = "filesystem";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        chunk_store_config = {
          max_look_back_period = "0s";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          shared_store = "filesystem";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
      # user, group, dataDir, extraFlags, (configFile)
    };
  };
}
