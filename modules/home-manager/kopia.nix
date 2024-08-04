{ inputs
, pkgs
, lib
, config
, ...
}:
{
  systemd.user = lib.mkIf pkgs.hostPlatform.isLinux {
    startServices = "sd-switch";
    services = {
      kopia = {
        Unit = {
          Description = "Kopia backup target";
          After = [ "network.target" ];
        };
        Service = {
          # Set scheduling for this service to be in the background
          # behind "everything else" so that backups don't really
          # compete with anything in the foreground. This is OK for
          # backups to take longer if they don't impact the system for
          # like gooey apps and whatever.
          #
          # The scheduling changes swap this from a 12sec task to
          # maybe 2ish minutes but only when really under
          # contention. If idle its the same.
          CPUSchedulingPolicy = "batch"; # Consider this a batch job for cpu, idle is possible too but hits this too hard
          IOSchedulingClass = "idle"; # If anything else is doing i/o its probably a priority to this
          IOSchedulingPriority = 7; # Lowest i/o priority
          Type = "oneshot";
          ExecStart = ../../static/src/bkp.sh;
          # Why is home-manager systemd services like nixos and lets
          # me just do pkgs = [list]; sigh
          Environment =
            [ "PATH=${pkgs.lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.kopia ]}" ];
        };
        # Let the timers run this not when/if the service is reloaded.
        #Install.WantedBy = [ "default.target" ];
      };
    };
    timers = {
      kopia = {
        Unit.Description = "Kopia backup schedule";
        Timer = {
          Unit = "kopia";
          RandomizedDelaySec = "55s";
          OnCalendar = [
            # 4x every hour roughly every 15 seconds during the weekday
            "Mon,Tue,Wed,Thu,Fri 08,09,10,11,12,13,14,15,16,17,18:7:3/15"
            # For Mon-Friday every hour outside of those hours except
            # past 10-6am where I should be sleeping
            "Mon,Tue,Wed,Thu,Fri 06,07,19,20,21,22:7"
            # And same on Sat/Sunday every hour just during the day in
            # same hours as ^^^
            "Sat,Sun 06,07,08,09,10,11,12,13,14,15,16,17,18,19,20:7"
          ];
        };
        Install = {WantedBy = [ "timers.target" ];
                   RequiredBy = [ "nas-backup.mount" ];
                  };
      };
    };
  };
}
