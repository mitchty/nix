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

        # yt-dlp-random-with-plugins
        # ytdl-sub-random-with-plugins

        yq-go
      ]
      ++ (lib.optionals pkgs.hostPlatform.isLinux [ libcgroup ]);
  };
}
