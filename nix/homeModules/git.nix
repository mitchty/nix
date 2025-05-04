{
  pkgs,
  ...
}:
{
  # TODO: need to convert this setup to not directly use .gitconfig files
  # Programs not (yet) worthy of their own .nix setup... so far who knows what
  # the future holds.
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-dash
      pkgs.gh-cal
    ];
  };
  home = {
    packages = with pkgs; [
      git-absorb
      git-extras
      git-lfs
      git-quick-stats
      git-recent
      git-sizer
      git-vendor
      gitFull
    ];
    file = {
      # TODO: age encryption need to brain a way to pass that into home
      # configuration or whatever age encryption is on the things to get working
      # so I can commit and push to github. Not a huge deal for now I can push
      # on an existing system until then.
      #".netrc".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/netrc".path;
      #".gh-cli-pub".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/gh-cli-pub".path;
      ".gitignore".source = ../../static/git/ignore;
      ".gitconfig-work".source = ../../static/git/config-work;
      ".gitconfig".text =
        (builtins.readFile ../../static/git/config)
        + (builtins.readFile ../../static/git/config-work-include);
    };
  };
}
