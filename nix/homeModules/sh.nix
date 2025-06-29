{
  pkgs,
  ...
}:
{
  # TODO: figure out emacsGcc then make this the defaults, for now vim is ok
  # EDITOR = "emacs -nw";
  # VISUAL = "emacs";
  home.sessionVariables = rec {
    EDITOR = "vim";
    VISUAL = EDITOR;
    GIT_EDITOR = EDITOR;
  };

  # .profile is mostly the same between nixos/macos, all I do is tack on macos stuff to the end of the profile if/when we're there.
  # home.file.".profile".text = lib.strings.fileContents ./.profile + "\n" + lib.strings.optionalString pkgs.stdenv.isDarwin lib.strings.fileContents ./.profile-darwin;
  home.file.".profile".text = pkgs.lib.strings.concatStringsSep "\n" (
    [
      (pkgs.lib.strings.fileContents ../../static/home/profile)
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      (pkgs.lib.strings.fileContents ../../static/home/profile-darwin)
    ]
  );

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
    jq.enable = true;

    # Options ref:
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
    zsh = {
      enable = true;
      enableCompletion = true;
      history = {
        size = 10000;
        save = 10000;
        path = "$HOME/.zsh_history";

        # Keep history clean, don't save this crap
        ignorePatterns = [
          "rm *"
          "pkill *"
          "kill *"
        ];

        ignoreDups = true;
        ignoreSpace = true;

        # Add timestamps to history
        extended = true;

        # And share between sessions
        share = true;
      };

      # Probably need to put more in here
      shellAliases = {
        edirs = "ls -d **/*(/^F)"; # empty directories
        dl = "cd ~/Desktop && noglob yt-dlp --";
        eod = "mt mitchty/org && git add journal && git ci -m \"journal: $(date +%Y-%b-%d)\"";
      };

      # Maybe make these uppercase? Meh been fine so far
      shellGlobalAliases = {
        silent = "> /dev/null 2>&1";
        noerr = "2> /dev/null";
        stdboth = "2>&1";
        # I mostly use(d) this to make firefox take up less cpu when I'm not
        # actively using it. Hopefully there is a better way to make it less joule
        # hungry.
        sigcont = "kill -CONT ";
        sigstop = "kill -STOP ";
      };

      # Everything we can't define ^^thataway^^
      initContent = (builtins.readFile ../../static/home/zshrc) + (builtins.readFile ../../src/lib.sh);
    };
  };
}
