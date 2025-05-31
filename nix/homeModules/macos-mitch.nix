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
    # sessionVariables = {
    #   BROWSER = "librewolf";
    #   GDK_DPI_SCALE = "1.25";
    #   QT_SCALE_FACTOR = "1.25";
    # };
    packages = with pkgs; [
      gron
    ];
  };
}
