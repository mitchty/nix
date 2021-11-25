{ config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.username = "mitch";
  home.homeDirectory = "/home/mitch";
  # home.stateVersion = "21.05";

  home.packages = with pkgs; [
    ag
    bind
    curl
    docker
    docker-compose
    dstat
    file
    git
    git-lfs
    gitAndTools.transcrypt
    glances
    htop
    iotop
    jq
    niv
    podman
    podman-compose
    syncthing
    tcpdump
    tmux
    wget
    xorg.xauth
    xrdp
  ];

  # TODO: convert zsh config to this
  # Options ref: https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
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

    # What the hell else would I want to do if I type a dirname? Execute it?
    autocd = true;

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
  };

  # TODO: convert emacs config to this setup and make the emacs overlay work...
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    # package = unstable.emacsGcc;
    # extraPackages = (epkgs: [ epkgs.vterm] );
  };
}
