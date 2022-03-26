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

  resticExcludes = pkgs.writeText "excludes" (builtins.readFile ../../static/restic/excludes);
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
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ restic ];
    launchd.user.agents.restic-backup = {
      script = ''
        #!/bin/bash
        # Note: /bin/bash so that I can add /bin/bash in security so
        # ~/Desktop... can be backed up via launchd
        #-*-mode: Shell-script; coding: utf-8;-*-
        : > ${cfg.logDir}/restic-backup-stderr.log

        # Don't bother backing up if we're not on a/c
        if command -v pmset > /dev/null 2>&1 && ! pmset -g ps | grep AC > /dev/null 2>&1; then
          printf "fatal: not on a/c, not bothering to backup\n" >&2
          exit 1
        fi

        # Hack here as the activation script order has launchd before any of the
        # secret generation, so if we are doing a deploy we need to wait a bit
        # before we can expect these files (symlinks really) to exist.
        # Only applicable as RunAtLoad = true
        sleep 10

        if [ ! -f ${config.age.secrets."restic/env/RESTIC_PASSWORD".path} ] &&
           [ ! -f ${config.age.secrets."restic/env/AWS_ACCESS_KEY".path} ] &&
           [ ! -f ${config.age.secrets."restic/env/AWS_SECRET_KEY".path} ]; then
          printf "fatal: cannot find env files\n" >&2
          exit 2
        fi

        export RESTIC_PASSWORD=$(cat ${config.age.secrets."restic/env/RESTIC_PASSWORD".path});
        export AWS_ACCESS_KEY=$(cat ${config.age.secrets."restic/env/AWS_ACCESS_KEY".path});
        export AWS_SECRET_KEY=$(cat ${config.age.secrets."restic/env/AWS_SECRET_KEY".path});

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
        ProcessType = "Adaptive";
        RunAtLoad = true;
        StandardErrorPath = "${cfg.logDir}/restic-backup-stderr.log";
        StandardOutPath = "${cfg.logDir}/restic-backup.log";
        StartInterval = 3600;
      };
    };
    launchd.user.agents.restic-prune = {
      script = ''
        #!${pkgs.bash}
        #-*-mode: Shell-script; coding: utf-8;-*-
        : > ${cfg.logDir}/restic-prune-stderr.log

        if [ ! -f ${config.age.secrets."restic/env/RESTIC_PASSWORD".path} ] &&
           [ ! -f ${config.age.secrets."restic/env/AWS_ACCESS_KEY".path} ] &&
           [ ! -f ${config.age.secrets."restic/env/AWS_SECRET_KEY".path} ]; then
          printf "fatal: cannot find env files\n" >&2
          exit 2
        fi

        export RESTIC_PASSWORD=$(cat ${config.age.secrets."restic/env/RESTIC_PASSWORD".path});
        export AWS_ACCESS_KEY=$(cat ${config.age.secrets."restic/env/AWS_ACCESS_KEY".path});
        export AWS_SECRET_KEY=$(cat ${config.age.secrets."restic/env/AWS_SECRET_KEY".path});

        {
          restic forget --verbose --tag auto --group-by 'paths,tags' --keep-hourly 24 --keep-daily 14 --keep-weekly 4 --keep-monthly 6 --keep-yearly 10 --repo ${cfg.repo}
          restic prune --verbose --repo ${cfg.repo}
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
        RunAtLoad = false;
        StandardErrorPath = "${cfg.logDir}/restic-prune-stderr.log";
        StandardOutPath = "${cfg.logDir}/restic-prune.log";
        StartInterval = 36000;
      };
    };
  };
}
