{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.restic;
  # Backup fragment only applicable to macos for the wrapper restic backup junk
  #
  # All this fragment does is uses mdfind to find stuff tagged with "don't back me up"
  # and/or pulls from the standard exclusions property list if it exists.
  #
  # All that just gets appended onto the stock .excludes file.
  darwinbits = ''
    sysexclude=/System/Library/CoreServices/backupd.bundle/Contents/Resources/StdExclusions.plist

    {
      # The .exludes file might not have a trailing \n so add it just in case
      # blank lines is not a huge problem
      printf "\n";

      # Anything that apps specify as don't backup this key
      /usr/bin/mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'";
      printf "\n";

      if [[ -f $sysexclude ]]; then
        # Stuff from here that time machine ignores, so guessing we should too
        #
        # Note, if I were backing up more than $HOME I'd add a loop and include
        # ContentsExcluded and PathsExcluded in as well as UserPathsExcluded
        #
        # Though the entire thing seems missing in recent macos versions so whatever.
        /usr/bin/defaults read $sysexclude UserPathsExcluded | sed -e 's/["]$//' -e '/^[(]$/d' -e '/^[)]$/d' -e 's/["][,]//' | tr -d '    "'
      fi
    } >> $EXCLUDES
  '';

  resticEnv = pkgs.writeScript "restic-env.sh" (builtins.readFile ../../secrets/crypt/restic-env.sh);
  resticExcludes = pkgs.writeText "excludes" (builtins.readFile ../../etc/restic-excludes);
in
{
  options = {
    services.restic = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If restic backups should be enabled or not.
        '';
      };

      homeDir = mkOption {
        type = types.nullOr types.path;
        default = "~";
        example = "/Users/foo";
        description = ''
          Path to backup, defaults to ~/$HOME
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

      repo = mkOption {
        type = types.str;
        default = "changeme";
        example = "s3:http://1.2.3.4:5678/example";
        description = ''
          The string representing the repo to backup to.
          Path to backup, defaults to ~/$HOME
        '';
      };

      # For the future...
      # resticPassword = mkOption {
      #   type = types.nullOr types.str;
      #   default = null;
      #   example = "somepassword";
      #   description = ''
      #     The RESTIC_PASSWORD env variable
      #   '';
      # };

      # s3Access = mkOption {
      #   type = types.nullOr types.str;
      #   default = null;
      #   example = "somestring";
      #   description = ''
      #     The AWS_ACCESS_KEY env variable
      #   '';
      # };

      # s3Secret = mkOption {
      #   type = types.nullOr types.str;
      #   default = null;
      #   example = "somelongerstring";
      #   description = ''
      #     The AWS_SECRET_KEY env variable
      #   '';
      # };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ restic ];
    launchd.user.agents.restic-backup = {
      script = ''
        #!${pkgs.bash}
        #-*-mode: Shell-script; coding: utf-8;-*-
        : > ${cfg.logDir}/restic-backup-stderr.log

        # Don't bother backing up if we're not on a/c
        if command -v pmset > /dev/null 2>&1 && ! pmset -g ps | grep AC > /dev/null 2>&1; then
          printf "not on a/c, not bothering to backup\n" >&2
          exit 1
        fi

        if ! grep OK ${resticEnv}; then
          printf "env file doesn't appear to be decrypted\n" >&2
          exit 1
        fi

        source ${resticEnv}

        EXCLUDES=$(mktemp /tmp/restic-backup-XXXXX)

        # Cleanup the .excludes file on exits
        cleanup() {
          [[ -e $EXCLUDES ]] && rm $EXCLUDES
        }

        trap cleanup EXIT

        # Create a bit of a dynamic exclude file (for macos mostly)
        cp ${resticExcludes} $EXCLUDES

        ${darwinbits}

        restic backup --verbose --one-file-system --repo ${cfg.repo} --exclude-file=$EXCLUDES --tag auto $HOME | ts

        date
        printf 'fin\n' >&2
        exit 0
      '';
      path = [ pkgs.restic pkgs.moreutils pkgs.coreutils pkgs.gnugrep ];

      # low priority io cause the backup doesn't need to take precedence for any i/o operations
      serviceConfig = {
        Label = "net.mitchty.restic-backup";
        LowPriorityIO = true;
        ProcessType = "Background";
        StandardOutPath = "${cfg.logDir}/restic-backup.log";
        StandardErrorPath = "${cfg.logDir}/restic-backup-stderr.log";
        RunAtLoad = true;
        StartInterval = 3600;
        # Once sops or age works on macos we want to replace the env setup with this...
        # EnvironmentVariables = {
        #   RESTIC_PASSWORD = "${cfg.resticPassword}";
        # };
      };
    };
    launchd.user.agents.restic-prune = {
      script = ''
        #!${pkgs.bash}
        #-*-mode: Shell-script; coding: utf-8;-*-
        : > ${cfg.logDir}/restic-prune-stderr.log

        if ! grep OK ${resticEnv}; then
          printf "env file doesn't appear to be decrypted\n" >&2
          exit 1
        fi

        source ${resticEnv}

        {
          restic forget --verbose --tag auto --group-by 'paths,tags' --keep-hourly 24 --keep-daily 14 --keep-weekly 4 --keep-monthly 6 --keep-yearly 10 --repo ${cfg.repo}
          restic prune --verbose --repo s3:http://10.10.10.190:8333/restic
          restic cache --cleanup
        } | ts

        date
        printf 'fin\n' >&2
        exit 0
      '';
      path = [ pkgs.restic pkgs.moreutils pkgs.coreutils pkgs.gnugrep ];

      # low priority io cause the backup doesn't need to take precedence for any i/o operations
      serviceConfig = {
        Label = "net.mitchty.restic-prune";
        LowPriorityIO = true;
        ProcessType = "Background";
        StandardOutPath = "${cfg.logDir}/restic-prune.log";
        StandardErrorPath = "${cfg.logDir}/restic-prune-stderr.log";
        RunAtLoad = false;
        StartInterval = 36000;
        # Once sops or age works on macos we want to replace the env setup with this...
        # EnvironmentVariables = {
        #   RESTIC_PASSWORD = "${cfg.resticPassword}";
        # };
      };
    };
  };
}
