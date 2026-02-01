{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
{
  config = {
    home.packages =
      with pkgs;
      [
        pkgs.unstable.yt-dlp-with-plugins
        pkgs.unstable.ytdl-sub-with-plugins
        yq-go
      ]
      ++ (lib.optionals pkgs.stdenv.hostPlatform.isLinux [ libcgroup ]);
  };
}
