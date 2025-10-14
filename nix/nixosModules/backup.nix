{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Backup runs as root for /var reasons
  uid = "0";
  gid = "0";
  agePath = "secrets/cifs/backup";

  creds = config.age.secrets."${agePath}".path;
in
{

  environment.systemPackages = [
    pkgs.kopia
    pkgs.dust
  ];

  age.secrets = {
    "${agePath}" = {
      file = ../../secrets/cifs/backup.age;
    };
  };

  fileSystems = inputs.self.lib.mkCifsMount {
    # /srv/backup is for backing up stuff as root like /var
    prefix = "/srv";
    mountpoint = "backup";
    share = "backup";
    inherit uid gid creds;
  };

  systemd.services.backup-var = {
    description = "backup /var/lib crap via kopia";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.kopia}/bin/kopia snapshot create --tags script:true --tags gihugic:true /var/lib/grafana /var/lib/karakeep /var/lib/prometheus2 /var/lib/loki /var/lib/private /var/lib/media --parallel=4";
    };
    requires = [
      "srv-backup.mount"
      "network-online.target"
    ];
    after = [
      "srv-backup.mount"
      "network-online.target"
    ];
  };

  systemd.timers.backup-var = {
    description = "when to backup /var/lib junk";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:11:07";
      Persistent = true;
      RandomizedDelaySec = "7m";
    };
  };
}
