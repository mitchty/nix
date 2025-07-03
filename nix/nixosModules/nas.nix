{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  fsAutomountOpts = [
    "x-systemd.automount"
    "x-systemd.idle-timeout=300"
    "x-systemd.mount-timeout=60s"
    "nofail"
  ];
  fsCifsPerfOpts = [
    "bsize=8388608"
    "rsize=131072"
    #"cache=loose" # TODO need to test this between nodes
  ];
  fsCifsDefaults = [
    "user" # NB keep this above exec or you can't run scripts off this mount point
    "mfsymlinks"
    "exec"
    "nofail"
    "forceuid"
    "forcegid"
    "soft"
    "rw"
    "vers=3"
    "credentials=${config.age.secrets."secrets/cifs/mitch".path}"
  ];
  # TODO: make this an option/cfg var param and stop being lazy
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
  ];
  fsUserMe = [
    "uid=1000"
    "gid=100"
  ];
in
{
  age.secrets = {
    "secrets/cifs/mitch" = {
      file = ../../secrets/cifs/mitch.age;
      owner = "mitch";
    };
  };

  fileSystems = {
    "/nas/media" = {
      device = "//s1.home.arpa/media";
      fsType = "cifs";
      options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
    };
    "/nas/bitbucket" = {
      device = "//s1.home.arpa/bitbucket";
      fsType = "cifs";
      options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
    };
    "/nas/backup" = {
      device = "//s1.home.arpa/backup";
      fsType = "cifs";
      options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
    };
  };
}
