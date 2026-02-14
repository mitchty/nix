{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.mitchty.sh;
  useFzf = cfg.historyBackend == "fzf";
  useAtuin = cfg.historyBackend == "atuin";
in
{
  options.mitchty.sh = {
    historyBackend = mkOption {
      type = types.enum [
        "default"
        "fzf"
        "atuin"
      ];
      default = "default";
      description = ''
        Shell history search backend to use.
        - default: use $SHELL built-in history
        - fzf: use fzf for local history search
        - atuin: use atuin with server sync for history search
      '';
    };
    atuinServerUrl = mkOption {
      type = types.str;
      default = "http://atuin.home.arpa:8888";
      description = "URL of the atuin sync server";
    };
  };

  config = {
    # .profile is mostly the same between nixos/macos, all I do is tack on macos
    # stuff to the end of the profile if/when we're there.
    # home.file.".profile".text = lib.strings.fileContents ./.profile + "\n" +
    # lib.strings.optionalString pkgs.stdenv.isDarwin lib.strings.fileContents
    # ./.profile-darwin;
    home = {
      file.".profile".text = pkgs.lib.strings.concatStringsSep "\n" (
        [
          (pkgs.lib.strings.fileContents ../../static/home/profile)
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          (pkgs.lib.strings.fileContents ../../static/home/profile-darwin)
        ]
      );

      # EDITOR = "emacs -nw";
      # VISUAL = "emacs";
      sessionVariables = rec {
        EDITOR = "vim";
        VISUAL = EDITOR;
        GIT_EDITOR = EDITOR;
      };
    };

    # Atuin encryption key - decrypt from agenix
    age.secrets."secrets/atuin/key" = mkIf useAtuin {
      file = ../../secrets/atuin/key.age;
      path = "${config.home.homeDirectory}/.local/share/atuin/key";
    };

    programs = {
      fzf = mkIf useFzf {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };

      atuin = mkIf useAtuin {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;

        settings = {
          sync_address = cfg.atuinServerUrl;
          auto_sync = true;
          sync_frequency = "5m";

          search_mode = "fuzzy";
          filter_mode = "global";
          filter_mode_shell_up_key_binding = "session";

          style = "compact";
          inline_height = 20;
          show_preview = true;

          max_preview_height = 4;
          show_help = true;
          exit_mode = "return-original";

          keymap_mode = "auto";

          secrets_filter = true;
          store_failed = true;
        };
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
        # // (optionalAttrs useAtuin {
        #   atuin-sync = "atuin sync";
        #   atuin-search = "atuin search";
        #   atuin-stats = "atuin stats";
        # });

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
  };
}
