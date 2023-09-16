{ config, lib, pkgs, options, ... }:

with lib;

let
  name = "mutagen";
  cfg = config.services.shared.${name};

  # Only used for launchd
  label = "net.mitchty.shared";
  fulllabel = "${label}.${name}";
in
{
  options = {
    services.shared.${name} = {
      enable = mkEnableOption "shared ${name} service";

      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = "For launchd, log directory.";
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
    (optionalAttrs (options ? launchd.user.agents) (mkIf (pkgs.hostPlatform.isDarwin) {
      environment.systemPackages = [ cfg.package ];
      launchd.user.agents.${name} = {
        script = ''
          #!/bin/bash
          # Note: /bin/bash so that I can add /bin/bash in security so
          # ~/Desktop... can be backed up via launchd
          #-*-mode: Shell-script; coding: utf-8;-*-
          ${pkgs.coreutils}/bin/install -Ddm755 ${cfg.logDir}/${label}/${name}
          . ${../../static/src/lib.sh}
          rotatelog 5 ${cfg.logDir}/${label}/${name}/stderr.log ${cfg.logDir}/${label}/${name}/stdout.log

          # Stop any existing daemon if present
          ${cfg.package}/bin/${name} daemon stop || :

          #
          exec ${cfg.package}/bin/${name} daemon start
        '';
        path = [ config.environment.systemPath ];

        # low priority io cause the sync doesn't need priority i/o wise generally
        serviceConfig = {
          Label = fulllabel;
          LowPriorityIO = true;
          ProcessType = "Adaptive";
          RunAtLoad = true;
          StandardErrorPath = "${cfg.logDir}/${label}/${name}/stderr.log";
          StandardOutPath = "${cfg.logDir}/${label}/${name}/stdout.log";
          StartInterval = 3600;
        };
      };
    }))
    (optionalAttrs (options ? systemd.services) (mkIf (pkgs.hostPlatform.isLinux) {
      environment.systemPackages = [ cfg.package ];
      systemd.services.${name} = {
        enable = true;
        wantedBy = [ "default.target" ];

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          Type = "forking";
          Description = "${name} user daemon";
          Restart = "on-failure";
          ExecStart = "${cfg.package}/bin/${name} daemon start";
        };
      };
    }))
  ]);
}
