{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
with lib;
let
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
  ];

  uid = "1000";
  gid = "100";
  agePath = "secrets/cifs/mitch";

  creds = config.age.secrets."secrets/cifs/mitch".path;
in
{
  config = {
    age.secrets = {
      "${agePath}" = {
        file = ../../secrets/cifs/mitch.age;
        owner = "mitch";
      };
    };

    fileSystems =
      inputs.self.lib.mkCifsMount rec {
        mountpoint = "media";
        share = "media";
        inherit uid gid creds;
      }
      // inputs.self.lib.mkCifsMount rec {
        mountpoint = "bitbucket";
        share = "bitbucket";
        inherit uid gid creds;
      }
      // inputs.self.lib.mkCifsMount rec {
        mountpoint = "backup";
        share = "backup";
        inherit uid gid creds;
      };
  };
}
