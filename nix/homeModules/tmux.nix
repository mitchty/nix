{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  formats = with pkgs.formats; {
    yaml = yaml { };
  };

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

  sh = {
    window_name = "sh";
    panes = [ "pane" ];
  };

  # terminal monitoring stuffs
  mon = {
    window_name = "mon";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          {
            # Bit of a hack but its not a huge deal for this to fail/exit its a
            # one time dealio so whatever. I was having super weird output with
            # optionals here in the yaml that I got sick of debugging.
            cmd = "onlinux sudo powerjoular ; exit";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            cmd = "btop";
            enter = true;
          }
        ];
      }
      # TODO: wat the hell works on macos too? yeet that in here.
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
      }
      {
        shell_command = [
          "gi mitchty/nix legacy"
        ];
      }
    ];
  };

  yt = {
    window_name = "yt/mon";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "hwatch -t -d word -n 60 ./stats.sh"
        ];
      }
      {
        shell_command = [
          {
            cmd = "dev=enp2s0 ./ytlatest.sh subs/all.yaml | ts";
          }
        ];
      }
    ];
  };

  ytprime = {
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "sudo powerjoular"
        ];
      }
      {
        shell_command = [
          "btop"
        ];
      }
      {
        shell_command = [
          "journalctl -fu podman-bgutil-ytdlp-pot-provider.service"
        ];
      }
      "pane"
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
        #        sleep_before = sleepDefault;
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
        # sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-srv -l";
          }
        ];
        # sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-wm2 -l";
          }
        ];
        # sleep_before = sleepDefault;
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-mb -l";
          }
        ];
        # sleep_before = sleepDefault;
      }
    ];
  };

  yeet = {
    window_name = "yeet";
    panes = [
      {
        shell_command = [
          "gi mitchty/yeet"
        ];
      }
    ];
  };

  ip = {
    window_name = "ip";
    panes = [
      {
        focus = true;
        shell_command = [
          "prg iocaine-powder"
        ];
      }
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
    # sleep_before = sleepDefault;
  };

  shenanigans = {
    window_name = "gh mt/shenanigans";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "nuke-libvirt.sh && pulumi up -yf"
        ];
        # sleep_before = sleepDefault;
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
    # sleep_before = sleepDefault;
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
        btop
        tmuxp
      ]
      ++ lib.optionals pkgs.hostPlatform.isLinux [
        powerjoular
      ];

    # tmuxp configs
    file = {
      ".config/tmuxp/mon.yml".source = formats.yaml.generate "mon-config" {
        start_directory = "~";
        session_name = "mon";
        windows = [ mon ];
      };

      ".config/tmuxp/shenanigans.yml".source = formats.yaml.generate "shenanigans-config" {
        start_directory = "~/src/pub/github.com/mitchty/shenanigans";
        session_name = "shenanigans";
        windows = [ shenanigans ];
      };

      ".config/tmuxp/nix.yml".source = formats.yaml.generate "nix-config" {
        start_directory = "~/src/pub/github.com/mitchty/nix";
        session_name = "nix";
        windows = [
          initial
          rebuildlocal
        ];
      };

      ".config/tmuxp/mutagen.yml".source = formats.yaml.generate "mutagen-config" {
        start_directory = "~";
        session_name = "mutagen";
        windows = [
          mutagen
        ];
      };

      ".config/tmuxp/journal.yml".source = formats.yaml.generate "journal-config" {
        start_directory = "~/src/pub/git.mitchty.net/mitchty/org";
        session_name = "journal";
        windows = [ journal ];
      };

      ".config/tmuxp/etc.yml".source = formats.yaml.generate "etc-config" {
        start_directory = "~/";
        session_name = "etc";
        windows = [
          initial
          mon
        ];
      };

      ".config/tmuxp/wip.yml".source = formats.yaml.generate "wip-config" {
        start_directory = "~/";
        session_name = "wip";
        windows = [
          ip
          yeet
        ];
      };

      ".config/tmuxp/yt.yml".source = formats.yaml.generate "yt-config" {
        start_directory = "/nas/media/internets";
        session_name = "yt";
        windows = [
          ytprime
          yt
        ];
      };

      # TODO: keep?
      # ".config/tmuxp/mb.yml".source = formats.yaml.generate "mb-config" {
      #   start_directory = "~/";
      #   session_name = "mb";
      #   windows = [
      #     initial
      #     rebuildall
      #     journal
      #   ];
      # };

      ".config/tmuxp/mbp.yml".source = formats.yaml.generate "mbp-config" {
        start_directory = "~/";
        session_name = "mbp";
        windows = [
          mon
          nix
          ip
          yeet
          journal
          sh
        ];
      };

      ".config/tmuxp/wm2.yml".source = formats.yaml.generate "wm2-config" {
        start_directory = "~/";
        session_name = "wm2";
        windows = [
          mon
          nix
          ip
          yeet
          sh
        ];
      };

      ".config/tmuxp/rtx.yml".source = formats.yaml.generate "rtx-config" {
        start_directory = "~/";
        session_name = "rtx";
        windows = [
          mon
          nix
          ip
          yeet
          journal
          sh
        ];
      };

      ".config/tmuxp/ark.yml".source = formats.yaml.generate "ark-config" {
        start_directory = "~/";
        session_name = "ark";
        windows = [
          mon
          nix
          ip
          yeet
          sh
        ];
      };
    };
  };
}
