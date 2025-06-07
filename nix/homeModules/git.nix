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

    age.secrets = {
      "git/netrc" = {
        file = ../../secrets/git/netrc.age;
        path = config.home.homeDirectory + "/.netrc";
      };
      "git/gh-cli-pub" = {
        file = ../../secrets/git/gh-cli-pub.age;
        path = config.home.homeDirectory + "/.gh-cli-pub";
      };
    };

    # TODO: figure out how to get home-manager agenix option to work.
    # Note: this is actually being setup in nixos/darwin modules not here
    # https://github.com/ryantm/agenix/issues/329
    #
    # I'm abusing the platform level decryption.
    # age.secrets."git/netrc".file = ../../secrets/git/netrc.age;

    home = {
      packages = with pkgs; [
        transcrypt # TODO: nuke me once everythings converted to main branch until then leave it around like a human tail
        gist
        git-absorb
        git-extras
        git-lfs
        git-quick-stats
        git-recent
        git-sizer
        git-vendor
        gitFull

        # TODO: Ab(use) the unofficial bitwarden cli and use that as a credential helper
        # How do I use this with a token? I can't auth with username/password...
        #
        # https://github.com/doy/rbw
        rbw
        pinentry-tty
      ];

      file = {
        ".gitignore".source = ../../static/git/ignore;
        ".gitconfig-work".source = ../../static/git/config-work;
        ".gitconfig".text =
          (builtins.readFile ../../static/git/config)
          + (builtins.readFile ../../static/git/config-work-include);
      };
    };
  };
}
