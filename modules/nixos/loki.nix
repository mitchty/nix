{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.loki;
  lokiDir = "/var/lib/loki";
in
{
  options.services.role.loki = {
    enable = mkEnableOption "Setup as a loki ingestor";
    cname = mkOption {
      type = types.str;
      default = "loki.home.arpa";
      description = "Internal dns domain to use for the loki cname";
    };
    # TODO: Need to make ip config a single derivation/list to pass in
    ip = mkOption {
      type = types.str;
      default = "10.10.10.128";
      description = "ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "enp142s0";
      description = "interface to add vip to";
    };
  };

  config = mkIf cfg.enable rec {
    networking = {
      interfaces = {
        "${cfg.iface}" = {
          ipv4.addresses = [
            {
              address = cfg.ip;
              prefixLength = 32;
            }
          ];
        };
      };
      firewall = {
        interfaces = {
          "${cfg.iface}" = {
            allowedTCPPorts = [
              # TODO: This is the loki port, figure out a better way to not copypasta this around
              3100
            ];
          };
        };
      };
    };

    services.loki = {
      enable = true;
      configuration = {
        analytics.reporting_enabled = false;
        server.http_listen_port = 3100;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = cfg.cname;
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
        };

        schema_config = {
          configs = [
            # {
            #   from = "2022-06-06";
            #   store = "boltdb-shipper";
            #   object_store = "filesystem";
            #   schema = "v11";
            #   index = {
            #     prefix = "index_";
            #     period = "24h";
            #   };
            # }
            {
              from = "2024-07-04";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "${lokiDir}/boltdb-shipper-active";
            cache_location = "${lokiDir}/boltdb-shipper-cache";
            cache_ttl = "24h";
          };

          tsdb_shipper = {
            active_index_directory = "${lokiDir}/tsdb-shipper-active";
            cache_location = "${lokiDir}/tsdb-shipper-cache";
            cache_ttl = "24h";
          };

          filesystem = {
            directory = "${lokiDir}/chunks";
          };
        };

        limits_config = {
          #          allow_metadata_structure = false;
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = lokiDir;
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };
  };
}
