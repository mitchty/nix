{ lib, ... }:
let
  # Cause stuff can be slow to warm up before a prompt shows up wait this long
  # first.
  sleepDefault = 3;

  # TODO: Learn how to unit test this stuff
  base = {
    start_directory = "~/";
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
    panes = [{
      shell_command = [
        "gi mitchty/nix"
      ];
      sleep_before = sleepDefault;
    }];
  };

  journal = {
    window_name = "mt/org";
    layout = "even-vertical";
    panes = [{
      shell_command = [
        "mt mitchty/org"
      ];
      sleep_before = sleepDefault;
    }];
  };

  nixos = {
    window_name = "gh/nixos";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "ssh -t srv.home.arpa \"zsh --login -i -c 'gi mitchty/nixos && nci'\""
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          "gi mitchty/nixos"
          "nci"
        ];
        sleep_before = sleepDefault;
      }
      {
        focus = true;
        shell_command = [
          "gi mitchty/nixos"
        ];
        sleep_before = sleepDefault;
      }
    ];
  };

  refactor = {
    window_name = "nixrefactor";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "gi mitchty/nix refactor"
        ];
        sleep_before = sleepDefault;
      }
    ];
  };

  rswip = {
    window_name = "rswip";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "ssh -t srv.home.arpa \"zsh --login -i -c 'cd ~/src/localhost/wip/ria/grep-lite && nrsci'\""
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          "cd ~/src/localhost/wip/ria/grep-lite && nrsci"
        ];
        sleep_before = sleepDefault;
      }
      {
        focus = true;
        shell_command = [
          "~/src/localhost/wip/ria/grep-lite"
        ];
        sleep_before = sleepDefault;
      }
    ];
  };

  wip = {
    window_name = "wip";
    panes = [ "pane" ];
  };

  rebuild = {
    shell_command = [
      "gi mitchty/nix"
      {
        cmd = "wtf rebuild";
        enter = false;
      }
    ];
    sleep_before = sleepDefault;
  };

  site-update = {
    shell_command = [
      "gi mitchty/nix"
      {
        cmd = "wtf site-update";
        enter = false;
      }
    ];
    sleep_before = sleepDefault;
  };

  rebuildall = {
    window_name = "rebuild";
    panes = [ site-update rebuild ];
  };

  rebuildlocal = {
    window_name = "rebuild";
    panes = [ rebuild ];
  };
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
    windows = [ initial btop ];
  });

  home.file.".config/tmuxp/wip.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "wip";
    windows = [ wip nix nixos rswip ];
  });

  home.file.".config/tmuxp/mb.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "mb";
    windows = [ initial rebuildall journal ];
  });

  home.file.".config/tmuxp/wm2.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "wm2";
    windows = [ initial rebuildall journal refactor ];
  });

  home.file.".config/tmuxp/srv.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "srv";
    windows = [ initial btop ];
  });

  home.file.".config/tmuxp/nexus.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "nexus";
    windows = [ initial btop ];
  });

  home.file.".config/tmuxp/wmb.yml".text = (lib.generators.toYAML { } {
    start_directory = "~/";
    session_name = "wmb";
    windows = [ initial rebuildlocal journal wip ];
  });
}
