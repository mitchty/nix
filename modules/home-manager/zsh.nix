{ config, ... }:
let
  nixpkgs-path = "nixpkgs=${config.home.homeDirectory}/.nix-inputs/nixpkgs";
  shenanigans = ''
    if ! echo $NIX_PATH | grep ${nixpkgs-path} > /dev/null 2>&1; then
      export NIX_PATH="${nixpkgs-path}:$NIX_PATH"
    fi
  '';
in {
  # Options ref:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";

      # Keep history clean, don't save this crap
      ignorePatterns = [ "rm *" "pkill *" "kill *" ];

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
    initExtra = (builtins.readFile ../../static/home/zshrc) + (builtins.readFile ../../static/src/lib.sh) + shenanigans;
  };
}
