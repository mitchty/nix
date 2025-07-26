{
  inputs,
  pkgs,
  lib,
  ...
}:
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

  # terminal monitoring stuffs
  mon = {
    window_name = "mon";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "btop"
        ];
      }
      # TODO: wat the hell works on macos too? yeet that in here.
    ]
    ++ lib.optional pkgs.hostPlatform.isLinux [
      {
        shell_command = [
          "sudo powerjoular"
        ];
      }
    ];
  };

  nix = {
    window_name = "gh/nix";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "gi mitchty/nix"
        ];
        sleep_before = sleepDefault;
      }
    ];
  };

  journal = {
    window_name = "mt/org";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "mt mitchty/org"
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

  mutagen = {
    window_name = "mutagen";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "hwatch -n 10 -t -d word -o stdout mutmon"
        ];
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-rtx -l";
          }
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-srv -l";
          }
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-wm2 -l";
          }
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-mb -l";
          }
        ];
        sleep_before = sleepDefault;
      }
    ];
  };

  wip = {
    window_name = "wip";
    panes = [
      {
        focus = true;
        shell_command = [
          {
            enter = true;
            cmd = "prg iocaine-powder";
          }
        ];
        sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "prg iocaine-powder";
          }
        ];
        sleep_before = sleepDefault;
      }
      # Temp on ice for a while
      # {
      #   shell_command = [
      #     {
      #       enter = true;
      #       cmd = "gi mitchty/yeet";
      #     }
      #   ];
      #   sleep_before = sleepDefault;
      # }
      # Need to think if I even want to bother with this anymore, if I do pick
      # it back up it'll probably just be in iocaine-powder as a bevy plugin I
      # build.
      # {
      #   shell_command = [
      #     {
      #       enter = true;
      #       cmd = "gi mitchty/moresus";
      #     }
      #   ];
      #   sleep_before = sleepDefault;
      # }
    ];
  };

  rebuild = {
    shell_command = [
      {
        cmd = "update && mobiledeploy deploytestedhost \$HOST && notify deploy \$HOST done";
        enter = false;
      }
    ];
    sleep_before = sleepDefault;
  };

  shenanigans = {
    window_name = "gh mt/shenanigans";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "nuke-libvirt.sh && pulumi up -yf"
        ];
        sleep_before = sleepDefault;
        enter = false;
      }
      {
        focus = true;
      }
    ];
  };

  # ai = {
  #   window_name = "ai";
  #   layout = "even-vertical";
  #   panes = [
  #     {
  #       focus = true;
  #     }
  #     {
  #       shell_command = [
  #         "pytest"
  #       ];
  #       enter = false;
  #     }
  #     {
  #       shell_command = [
  #         "gi mitchty/open-webui-cli"
  #       ];
  #       enter = false;
  #     }
  #   ];
  # };

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
    panes = [
      site-update
      rebuild
    ];
  };

  rebuildlocal = {
    window_name = "rebuild";
    panes = [ rebuild ];
  };
in
rec {
  # Look at pkgs.tmuxPlugins
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/tmux-plugins/default.nix
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    # This no worky doing in tmux.conf
    # prefix = "C-\\";
    extraConfig = builtins.readFile ../../static/tmux/tmux.conf;
  };

  home = {
    packages =
      with pkgs;
      [
        #        btop
        tmuxp
      ]
      ++ lib.optionals pkgs.hostPlatform.isLinux [
        powerjoular
      ];

    # tmuxp configs
    file = {
      ".config/tmuxp/mon.yml".text = lib.generators.toYAML { } {
        start_directory = "~";
        session_name = "mon";
        windows = [ mon ];
      };

      # ".config/tmuxp/ai.yml".text = (
      #   lib.generators.toYAML { } {
      #     start_directory = "~/src/pub/github.com/mitchty/teketeke";
      #     session_name = "ai";
      #     windows = [ ai ];
      #   }
      # );

      ".config/tmuxp/shenanigans.yml".text = lib.generators.toYAML { } {
        start_directory = "~/src/pub/github.com/mitchty/shenanigans";
        session_name = "shenanigans";
        windows = [ shenanigans ];
      };

      ".config/tmuxp/nix.yml".text = lib.generators.toYAML { } {
        start_directory = "~/src/pub/github.com/mitchty/nix";
        session_name = "nix";
        windows = [
          initial
          rebuildlocal
          refactor
        ];
      };

      ".config/tmuxp/mutagen.yml".text = lib.generators.toYAML { } {
        start_directory = "~";
        session_name = "mutagen";
        windows = [
          mutagen
        ];
      };

      ".config/tmuxp/journal.yml".text = lib.generators.toYAML { } {
        start_directory = "~/src/pub/git.mitchty.net/mitchty/org";
        session_name = "journal";
        windows = [ journal ];
      };

      ".config/tmuxp/etc.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "etc";
        windows = [
          initial
          mon
        ];
      };

      ".config/tmuxp/wip.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "wip";
        windows = [ wip ];
      };

      ".config/tmuxp/mb.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "mb";
        windows = [
          initial
          rebuildall
          journal
        ];
      };

      ".config/tmuxp/mbp.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "mbp";
        windows = [
          mon
          nix
          wip
          journal
        ];
      };

      ".config/tmuxp/wm2.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "wm2";
        windows = [
          mon
          nix
          wip
        ];
      };

      ".config/tmuxp/rtx.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "rtx";
        windows = [
          mon
          nix
          wip
        ];
      };

      ".config/tmuxp/srv.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "srv";
        windows = [
          initial
          mon
        ];
      };

      ".config/tmuxp/nexus.yml".text = lib.generators.toYAML { } {
        start_directory = "~/";
        session_name = "nexus";
        windows = [
          initial
          mon
        ];
      };
    };
  };
}
