{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.shared.syncthing;
  name = "syncthing";
  label = "net.mitchty";
  fulllabel = "${label}.${name}";
in
{
  options = {
    services.shared.${name} = {
      enable = mkEnableOption "shared syncthing service";

      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = "Base log directory, only applicable to macos.";
      };

      package = mkOption {
        default = pkgs.${name};
        defaultText = "pkgs.${name}";
        description = "Which derivation to use";
        type = types.package;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (options ? launchd.user.agents) (mkIf (pkgs.hostPlatform.isDarwin) {
      launchd.user.agents.syncthing = {
        environment.systemPackages = with pkgs; [ cfg.package ];
        script = ''
          #!/bin/bash
          # Note: /bin/bash so that I can add /bin/bash in security so
          # ~/Desktop... can be backed up via launchd
          #-*-mode: Shell-script; coding: utf-8;-*-
          ${pkgs.coreutils}/bin/install -Ddm755 ${cfg.logDir}/${label}/${name}
          . ${../../static/src/lib.sh}
          rotatelog 5 ${cfg.logDir}/${label}/${name}/stderr.log ${cfg.logDir}/${label}/${name}/stdout.log

          # Stop any existing daemon if present
          pkill ${name} || :

          ${cfg.package}/bin/syncthing
          exit $?
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
    (optionalAttrs (options ? systemd.user.services) (mkIf (pkgs.hostPlatform.isLinux) {
      # https://docs.syncthing.net/users/firewall.html
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPortRanges = [
        { from = 21027; to = 21027; }
        { from = 22000; to = 22000; }
      ];
      systemd.user.services.syncthing = {
        enable = true;
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Description = "syncthing user daemon";
          Restart = "on-abort";
          ExecStart = "${cfg.package}/bin/${name}";
        };
      };
    }))
  ]);
}
