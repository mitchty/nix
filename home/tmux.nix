{ ... }: {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    # This no worky doing in tmux.conf
    # prefix = "C-\\";
    extraConfig = builtins.readFile ./tmux.conf;
  };

  # Setup some tmuxp configs
  home.file.".config/tmuxp/etc.yml".source = ../static/tmuxp/etc.yml;
  home.file.".config/tmuxp/nix.yml".source = ../static/tmuxp/nix.yml;

  # TODO: Host specific configs, deal with conditionalizing later in a module
  home.file.".config/tmuxp/mb.yml".source = ../static/tmuxp/mb.yml;
  home.file.".config/tmuxp/workmb.yml".source = ../static/tmuxp/workmb.yml;
}
