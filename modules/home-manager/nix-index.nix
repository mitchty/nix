{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.nix-index;
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
in
{
  options.modules.services.nix-index =
    {
      enable = mkEnableOption "For now used to indicate a system is/n't one that has a graphical login.";

      # Only applicable/used in darwin
      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = ''
          Base log directory, only applicable to macos.
        '';
      };
    };
  # pkgs.lib.last (pkgs.lib.splitString "-" pkgs.system)
  config =
    let
      common = {
        path = [ pkgs.moreutils pkgs.coreutils pkgs.gnugrep ];
      };
    in
    # mkIf cfg.enable (mkMerge [
      #   (if isDarwin then {
      #     launchd.user.agents.nix-index = {
      #     script = ''
      #             #!${pkgs.bash}
      #             #-*-mode: Shell-script; coding: utf-8;-*-
      #             : > ${cfg.logDir}/nix-index-stderr.log
      #             ${pkgs.nix-index}/bin/nix-index
      #             date
      #             printf 'fin\n' >&2
      #             exit 0
      #     '';

      #     # low priority io cause the backup doesn't need to take precedence for any i/o operations
      #     serviceConfig = {
      #       Label = "net.mitchty.nix-index";
      #       LowPriorityIO = true;
      #       ProcessType = "Background";
      #       StandardOutPath = "${cfg.logDir}/nix-index.log";
      #       StandardErrorPath = "${cfg.logDir}/nix-index-stderr.log";
      #       StartInterval = 86400;
      #       # Why does this fail?
      #       # StartCalendarInterval = {WeekDay = 0; Hour = 6; Minute = 35;};
      #     };
      #     };
      #   } // common else {
      #   systemd.user.services.nix-index = {
      #     Unit = {
      #       Description = "Index Nix packages for search with nix-locate";
      #     };

      #     Service = {
      #       Type = "simple";
      #       ExecStart = "${pkgs.nix-index}/bin/nix-index";
      #     };

      #     Install = {
      #       WantedBy = [ "default.target" ];
      #     };
      #   };

      #   systemd.user.timers.nix-index =
      #     {
      #       Unit = {
      #         Description = "Run nix-index service periodically";
      #       };

      #       Timer = {
      #         Persistent = true;
      #         WakeSystem = false;
      #         # Run the service once a day
      #         OnUnitActiveSec = 86400;
      #       };

      #       Install = {
      #         WantedBy = [ "default.target" ];
      #       };
      #     };
      #   } // common )]);
      }
