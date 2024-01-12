{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nix-index;
in
{
  options = {
    services.nix-index = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If nix-index should be enabled or not.
        '';
      };
      logDir = mkOption {
        type = types.nullOr types.path;
        default = "/Users/mitch/Library/Logs";
        example = "~/Library/Logs";
        description = ''
          Base log directory, only applicable to macos.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    programs.nix-index.enable = true;

    environment.systemPackages = (lib.attrVals [ "nix-index" ] pkgs);
    launchd.user.agents.nix-index = {
      script = ''
        #!${pkgs.bash}
        #-*-mode: Shell-script; coding: utf-8;-*-
        : > ${cfg.logDir}/nix-index-stderr.log
        ${pkgs.nix-index}/bin/nix-index
        date
        printf 'fin\n' >&2
        exit 0
      '';
      path = [ pkgs.restic pkgs.moreutils pkgs.coreutils pkgs.gnugrep ];

      # low priority io cause the backup doesn't need to take precedence for any i/o operations
      serviceConfig = {
        Label = "net.mitchty.nix-index";
        LowPriorityIO = true;
        ProcessType = "Background";
        StandardOutPath = "${cfg.logDir}/nix-index.log";
        StandardErrorPath = "${cfg.logDir}/nix-index-stderr.log";
        StartInterval = 86400;
        # Why does this fail?
        # StartCalendarInterval = {WeekDay = 0; Hour = 6; Minute = 35;};
      };
    };
  };
}
