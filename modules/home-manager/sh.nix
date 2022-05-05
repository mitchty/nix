{ pkgs, ... }: {
  # TODO: figure out emacsGcc then make this the defaults, for now vim is ok
  # EDITOR = "emacs -nw";
  # VISUAL = "emacs";
  home.sessionVariables = rec {
    EDITOR = "vim";
    VISUAL = EDITOR;
    GIT_EDITOR = EDITOR;
  };

  # .profile is mostly the same between nixos/macos
  # home.file.".profile".text = lib.strings.fileContents ./.profile + "\n" + lib.strings.optionalString pkgs.stdenv.isDarwin lib.strings.fileContents ./.profile-darwin;
  home.file.".profile".text = pkgs.lib.strings.concatStringsSep "\n" ([
    (pkgs.lib.strings.fileContents ../../static/home/profile)
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    (pkgs.lib.strings.fileContents ../../static/home/profile-darwin)
  ]);
}
