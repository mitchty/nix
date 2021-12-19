{ ... }: {
  # TODO: figure out emacsGcc then make this the defaults, for now vim is ok
  # EDITOR = "emacs -nw";
  # VISUAL = "emacs";
  home.sessionVariables = rec {
    EDITOR = "vim";
    VISUAL = EDITOR;
    GIT_EDITOR = EDITOR;
  };

  # TODO: Is this a good spot for this?
  home.file.".profile".source = ./.profile;
}
