{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  config = {
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

    age.secrets."git/netrc".file = ../../secrets/git/netrc.age;

    home = {
      packages = with pkgs; [
        transcrypt
        gist
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
        # NO WORKY
        #        ".netrc".source = config.lib.file.mkOutOfStoreSymlink config.age.secrets."git/netrc".path;

        # TODO: using config.age.secrets.name.path doesn't work directly ref:
        # https://github.com/ryantm/agenix/issues/329
        ".netrc".source = config.lib.file.mkOutOfStoreSymlink "/run/agenix/git/netrc";
        #".gh-cli-pub".source = config.lib.file.mkOutOfStoreSymlink age.secrets."git/gh-cli-pub".path;
        ".gitignore".source = ../../static/git/ignore;
        ".gitconfig-work".source = ../../static/git/config-work;
        ".gitconfig".text =
          (builtins.readFile ../../static/git/config)
          + (builtins.readFile ../../static/git/config-work-include);
      };
    };
  };
}
