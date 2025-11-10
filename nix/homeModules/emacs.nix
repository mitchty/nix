{
  pkgs,
  lib,
  ...
}:
let
  enableFullBuild = import ../../hacks/flake-check.nix;
  # TODO: keep? Its useful but not used...
  mkIfElse =
    p: yes: no:
    lib.mkMerge [
      (lib.mkIf p yes)
      (lib.mkIf (!p) no)

    ];
in
{
  # For some god knows reason sometimes these files cause issues over time with
  # magit. I'm not debugging that, this was easier to port from ye olde setup to
  # fix the wonkiness.
  #
  # FUTURE MITCH REMOVE AT YOUR OWN DUM PERIL
  home.activation.cleanEmacsTmpDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.elc ~/.emacs.d/custom.el ~/.emacs.d/elpa ~/.emacs.d/eln-cache ~/.cache/org-persist ~/.emacs.d/tmp
    $DRY_RUN_CMD install -dm755 ~/.emacs.d/tmp
  '';

  programs.emacs = lib.optionalAttrs enableFullBuild {
    enable = true;
    package = pkgs.wrappedEmacs;
    #    package = pkgs.myEmacs;
    # extraPackages = epkgs:
    #   with epkgs; [
    #     #        eglot-booster
    #   ];
  };
}
