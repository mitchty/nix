{ ... }: {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    # This no worky doing in tmux.conf
    # prefix = "C-\\";
    extraConfig = builtins.readFile ./tmux.conf;
  };

  # Setup some tmuxp configs
  home.file.".config/tmuxp/etc.yml".source = ./etc.yml;
  home.file.".config/tmuxp/nix.yml".source = ./nix.yml;

  # TODO: Host specific configs, deal with conditionalizing later
  home.file.".config/tmuxp/mb.yml".source = ./mb.yml;
}
