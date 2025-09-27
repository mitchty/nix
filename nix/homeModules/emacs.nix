{
  pkgs,
  lib,
  ...
}:
{
  # For some god knows reason sometimes these files cause issues over time with
  # magit. I'm not debugging that, this was easier to port from ye olde setup to
  # fix the wonkiness.
  #
  # FUTURE MITCH REMOVE AT YOUR OWN DUM PERIL
  home.activation.cleanEmacsTmpDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.elc ~/.emacs.d/custom.el ~/.emacs.d/elpa ~/.emacs.d/eln-cache ~/.cache/org-persist ~/.emacs.d/tmp
  '';

  programs.emacs = {
    enable = true;
    package = pkgs.wrappedEmacs;
    #    package = pkgs.myEmacs;
    # extraPackages = epkgs:
    #   with epkgs; [
    #     #        eglot-booster
    #   ];
  };
}
