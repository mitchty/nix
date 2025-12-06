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
        yt-dlp-with-plugins
        ytdl-sub-with-plugins
        yq-go
      ]
      ++ (lib.optionals pkgs.hostPlatform.isLinux [ libcgroup ]);
  };
}
