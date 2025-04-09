{
  pkgs,
  ...
}:
{
  programs.emacs = {
    enable = true;
    package = pkgs.myEmacs;
    # extraPackages = epkgs:
    #   with epkgs; [
    #     #        eglot-booster
    #   ];
  };
}
