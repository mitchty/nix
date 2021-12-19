{ config, pkgs, ... }: {
  imports = [
    ./sh.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./syncthing.nix
  ];

  programs.home-manager.enable = true;
  home.username = "mitch";
  # home.homeDirectory = "/home/mitch";

  home.packages = with pkgs; [
    ag
    age
    bind
    curl
    docker
    docker-compose
    #    dstat
    emacs
    file
    #    firefox
    git
    git-lfs
    gitAndTools.transcrypt
    glances
    # TODO: Figure out allowfreepredicate for home-manager
    # google-chrome
    htop
    #    iotop
    mercurial
    niv
    podman
    #    podman-compose
    syncthing
    tcpdump
    tmux
    vim
    wget
    xorg.xauth
    #    xrdp
  ];

  # TODO: Finish porting emacs config over also the overlay isn't working via
  # home-manager switch for some reason future me fix
  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacsGcc;
  # };

  # Stuff not worthy of its own .nix file
  programs.jq.enable = true;
}
