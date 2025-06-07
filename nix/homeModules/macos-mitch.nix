{
  inputs,
  pkgs,
  ...
}:
{
  imports = with inputs.self.homeModules; [
    common
    emacs
  ];

  home = {
    packages = with pkgs; [
      utm
      ytdl-sub
      yt-dlp
    ];
  };
}
