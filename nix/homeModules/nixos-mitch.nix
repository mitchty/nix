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
    stateVersion = "24.11";
    sessionVariables = {
      BROWSER = "librewolf";
      GDK_DPI_SCALE = "1.25";
      QT_SCALE_FACTOR = "1.25";
      DICTDIR = "${pkgs.hunspellDicts.en_US}/share/hunspell";
    };
    packages = with pkgs; [
      flac

    ];
  };
}
