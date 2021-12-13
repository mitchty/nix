{ ... }: {
  programs.tmux = {
    enable = true;
    tmuxinator.enable = true;
    keyMode = "vi";
    # This no worky doing in tmux.conf
    # prefix = "C-\\";
    extraConfig = builtins.readFile ./tmux.conf;
  };

  # Setup some tmuxinator configs
  home.file.".config/tmuxinator/etc.yml".source = ./etc.yml;
  home.file.".config/tmuxinator/nix.yml".source = ./nix.yml;
}
