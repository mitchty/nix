{
  pkgs,
  ...
}:
{
  programs.emacs = {
    enable = true;
    package = pkgs.wrappedEmacs;
    # extraPackages = epkgs:
    #   with epkgs; [
    #     #        eglot-booster
    #   ];
  };
}
