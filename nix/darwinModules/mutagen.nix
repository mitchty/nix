{
  config,
  lib,
  pkgs,
  options,
  ...
}:

with lib;

# TODO: should this be home-manager instead?
let
  name = "mutagen";
  cfg = config.services.shared.${name};

  # Only used for launchd
  label = "net.mitchty.shared";
  fulllabel = "${label}.${name}";

  # Path to the mutagen config in the repo
  mutagenConfig = ../../static/home/mutagen.yaml;
in
{
  options = {
    services.shared.${name} = {
      enable = mkEnableOption "${name} service";

      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = "For launchd, log directory.";
      };

      homeDir = mkOption {
        type = types.path;
        default = "/Users/mitch/Library/Application Support/mutagen";
        example = "/Users/mitch/Library/Application Support/mutagen";
        description = "Writable HOME directory for mutagen daemon";
      };

      package = mkOption {
        default = pkgs.${name};
        defaultText = "pkgs.${name}";
        description = "Which derivation to use";
        type = types.package;
      };

      user = mkOption {
        default = "nobody";
        defaultText = "nobody";
        description = "For systemd, user to use for serviceConfig";
        type = types.str;
      };

      group = mkOption {
        default = "nobody";
        defaultText = "nobody";
        description = "For systemd, group to use for serviceConfig";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (options ? launchd.user.agents) (
      mkIf pkgs.stdenv.hostPlatform.isDarwin {
        environment.systemPackages = [ cfg.package ];
        launchd.user.agents.${name} = {
          path = [ config.environment.systemPath ];

          # For this to save on security shenanigans in the gooey, abuse /bin/bash
          # for doing work along with ProgramArguments instead of script.
          serviceConfig = {
            EnvironmentVariables = {
              MUTAGEN_LOG_LEVEL = "trace";
              HOME = cfg.homeDir;
            };
            ProgramArguments = [
              "/bin/bash"
              "-c"
              ''
                ${pkgs.coreutils}/bin/install -Ddm755 ${cfg.logDir}/${label}/${name};
                ${pkgs.coreutils}/bin/install -Ddm755 ${cfg.homeDir};
                ${pkgs.coreutils}/bin/ln -sf ${mutagenConfig} ${cfg.homeDir}/.mutagen.yml;
                . ${../../src/lib.sh};
                rotatelog 5 ${cfg.logDir}/${label}/${name}/stderr.log ${cfg.logDir}/${label}/${name}/stdout.log
                cd ${cfg.homeDir}
                pkill ${name}
                exec ${cfg.package}/bin/${name} daemon run
              ''
            ];
            Label = fulllabel;
            WatchPaths = [ (toString mutagenConfig) ];

            # low priority io cause the sync doesn't need priority i/o wise generally
            LowPriorityIO = true;
            ProcessType = "Adaptive";
            RunAtLoad = true;
            StandardErrorPath = "${cfg.logDir}/${label}/${name}/stderr.log";
            StandardOutPath = "${cfg.logDir}/${label}/${name}/stdout.log";
            StartInterval = 3600;
          };
        };
      }
    ))
  ]);
  # }))
  #   (optionalAttrs (options ? systemd.services) (mkIf (pkgs.hostPlatform.isLinux) {
  #     environment.systemPackages = [ cfg.package ];

  #     systemd.services.${name} = {
  #       enable = true;
  #       wantedBy = [ "default.target" ];
  #       description = "${name} user daemon";

  #       serviceConfig = {
  #         User = cfg.user;
  #         Group = cfg.group;
  #         Restart = "on-failure";
  #         ExecStart = "${cfg.package}/bin/${name} daemon run";
  #       };
  #       environment.MUTAGEN_LOG_LEVEL = "trace";
  #     };
  #   }))
  # ]);
}
