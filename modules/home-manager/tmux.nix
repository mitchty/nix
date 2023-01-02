{ lib, ... }:
let
  # TODO: Learn how to unit test this stuff
  base = {
    start_directory = "~/";
  };

  # TODO: need to nix-ify the syncthing setup I have
  syncthing = {
    window_name = "syncthing";
    panes = [ "pkill syncthing; syncthing" ];
  };

  initial = {
    window_name = "sh";
    panes = [ "pane" ];
    focus = true;
  };

  btop = {
    window_name = "btop";
    panes = [ "btop" ];
  };

  nix = {
    window_name = "gh/nix";
    layout = "even-vertical";
    panes = [ "gi mitchty/nix" ];
  };

  nixos = {
    window_name = "gh/nixos";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "ssh -t srv.home.arpa \"zsh --login -i -c 'gi mitchty/nixos && nci'\""
        ];
      }
      {
        shell_command = [
          "gi mitchty/nixos"
          "nci"
        ];
      }
      {
        focus = true;
        shell_command = [
          "gi mitchty/nixos"
        ];
      }
    ];
  };

  rswip = {
    window_name = "rswip";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "ssh -t srv.home.arpa \"zsh --login -i -c 'cd ~/src/pub/wip/ria/grep-lite && nrsci'\""
        ];
      }
      {
        shell_command = [
          "cd ~/src/pub/wip/ria/grep-lite && nrsci"
        ];
      }
      {
        focus = true;
        shell_command = [
          "~/src/pub/wip/ria/grep-lite"
        ];
      }
    ];
  };

  yolo = {
    window_name = "yolo";
    panes = [ ". ~/src/pub/github.com/mitchty/nix/static/src/ssh.sh" ];
  };

  wip = {
    window_name = "wip";
    panes = [ "pane" ];
  };

  deploy = {
    shell_command = [
      "gi mitchty/nix"
      {
        cmd = "deploy";
        enter = false;
      }
    ];
  };

  site-update = {
    shell_command = [
      "gi mitchty/nix"
      {
        cmd = "site-update";
        enter = false;
      }
    ];
  };

  deployall = {
    window_name = "deploy";
    panes = [ site-update deploy ];
  };

  deploylocal = {
    window_name = "deploy";
    panes = [ site-update deploy ];
  };

  # nix = {
  #   window_name = "nixdev";
  #   panes =[
  #     {
  #       shell_command = [
  #         "gi mitchty/nix"
  #         {
  #           cmd = "site-update";
  #           enter = "false";
  #         }
  #       ];
  #     }
  #     {
  #       shell_command = [
  #         "gi mitchty/nix"
  #         {
  #           cmd = "deploy";
  #           enter = "false";
  #         }
  #       ];
  #     }
  #   ];
  # };
in
rec {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    # This no worky doing in tmux.conf
    # prefix = "C-\\";
    extraConfig = builtins.readFile ../../static/tmux/tmux.conf;
  };

  # Setup some tmuxp configs
  home.file.".config/tmuxp/etc.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "etc";
    windows = [ initial syncthing btop ];
  });

  home.file.".config/tmuxp/wip.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "wip";
    windows = [ wip nix nixos rswip ];
  });

  home.file.".config/tmuxp/mb.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "mb";
    windows = [ initial syncthing deployall ];
  });

  # TODO: Get syncthing into a user systemd unit or something
  home.file.".config/tmuxp/srv.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "srv";
    windows = [ initial syncthing btop ];
  });

  # TODO: Get syncthing into a user systemd unit or something
  home.file.".config/tmuxp/nexus.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "nexus";
    windows = [ initial syncthing btop ];
  });

  home.file.".config/tmuxp/wmb.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "wmb";
    windows = [ initial deploylocal yolo wip ];
  });
}
