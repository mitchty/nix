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
  # TODO: Learn how to unit test this stuff
  base = {
    start_directory = "~/";
  };

  clear = {
    shell_command = [
      {
        cmd = "clear";
        enter = true;
      }
    ];
  };

  initial = {
    window_name = "sh";
    panes = [ "pane" ];
    focus = true;
  };

  sh = {
    window_name = "sh";
    panes = [ clear ];
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

  # gateway terminal monitoring general
  gwmon = {
    window_name = "mon";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          {
            cmd = "sudo powerjoular";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            # keep track of how big reverse proxy crap is
            cmd = "sudo ${pkgs.hwatch}/bin/hwatch -t -d word -n 60 du -hs /var/cache/nginx/cache/docker /var/lib/ncps";
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
    ];
  };

  # gateway network monitoring pane
  gwnmon = {
    window_name = "netmon";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          {
            cmd = "sudo ${pkgs.hwatch}/bin/hwatch -t -d word -n 5 ip -br a";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            cmd = "sudo ${pkgs.hwatch}/bin/hwatch -t -d word -n 60 fail2ban-client banned";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            # refused connection messages get puked out to dmesg
            cmd = "sudo dmesg -wT";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            cmd = "journalctl -f -u dhcpcd -u radvd";
            enter = true;
          }
        ];
      }
      {
        shell_command = [
          {
            cmd = "sudo nftrace monitor | ts | grep --color -E 'ip6'";
            enter = true;
          }
        ];
      }
    ];
  };

  nix = {
    window_name = "gh/nix";
    layout = "even-vertical";
    start_directory = "~/src/pub/github.com/mitchty/nix";
    panes = [
      clear
      clear
    ];
  };

  yt = {
    window_name = "yt/mon";
    layout = "tiled";
    start_directory = "/nas/media/internets";
    panes = [
      {
        shell_command = [
          "$CARGO_TARGET_DIR/release/ythelper dl --subscription subs/all.yaml"
        ];
      }
      {
        shell_command = [
          "hwatch -t -d word -n 60 /nas/media/internets/stats.sh"
        ];
      }
      {
        shell_command = [
          "${pkgs.hwatch}/bin/hwatch -t -d word -n 180 $CARGO_TARGET_DIR/release/ythelper stats --subscription subs/all.yaml --limit 15"
        ];
      }
      {
        shell_command = [
          "${pkgs.hwatch}/bin/hwatch -t -d word -n 180 $CARGO_TARGET_DIR/release/ythelper info --subscription subs/all.yaml"
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
      clear
    ];
  };

  journal = {
    window_name = "h/org";
    layout = "even-vertical";
    start_directory = "~/src/prv/git.home.arpa/mitch/org";
    panes = [ clear ];
  };

  mutagen = {
    window_name = "mutagen";
    layout = "even-vertical";
    panes = [
      {
        shell_command = [
          "${pkgs.hwatch}/bin/hwatch -n 10 -t -d word -o stdout mutmon"
        ];
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-rtx -l";
          }
        ];
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-wm2 -l";
          }
        ];
      }
      {
        shell_command = [
          {
            enter = true;
            cmd = "mutagen sync monitor src-mb -l";
          }
        ];
      }
    ];
  };

  yeet = {
    window_name = "yeet";
    start_directory = "~/src/pub/github.com/mitchty/yeet";
    panes = [ clear ];
  };

  ghpage = {
    window_name = "ghpage";
    start_directory = "~/src/pub/github.com/mitchty/mitchty.github.io";
    panes = [ clear ];
  };

  ip = {
    window_name = "ip";
    start_directory = "~/src/prv/git.home.arpa/mitch/iocainepowder";
    panes = [ clear ];
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
  #         "cd ~/src/pub/github.com/mitchty/open-webui-cli"
  #       ];
  #       enter = false;
  #     }
  #   ];
  # };
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
        # nixpkgs 25.05 release branch btop now causes llvm 19 to build on
        # darwin and the dam thing fails one test out of like 60k ungh.
        unstable.btop
        tmuxp
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        powerjoular
        nftrace
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
          ghpage
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
          ghpage
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
          ghpage
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
          ghpage
          journal
          sh
        ];
      };

      ".config/tmuxp/gw0.yml".source = formats.yaml.generate "ark-config" {
        start_directory = "~/";
        session_name = "gw0";
        windows = [
          gwmon
          gwnmon
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
