{ inputs, ... }:
{
  system = "aarch64-darwin";
  modules = [
    inputs.home-manager.darwinModules.home-manager
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaNLdykXNG7SbXyEFV3q1OVevNbIxSb8Of0AnSLxR11";
        tags = [
          "wireguard"
          "backup"
          "macos"
        ];
      };

      imports =
        with inputs.self.darwinModules;
        [
          common
          laptop
          mutagen
          age
          # ollama
          llama-swap
          wireguard
        ]
        ++ (with inputs.self.crossplatformModules; [
          mosh
          nix
        ]);

      services = {
        common.mosh.enable = true;
        mitchty = {
          age.enable = true;
          # ollama.enable = false;
          llama-swap.enable = true;
          wireguard = {
            enable = true;
            role = "client";
            address = [ "192.168.255.6/32" ];
            privateKeyFile = "secrets/wireguard/prv/mbp";
            dns = [ "10.10.10.1" ];
            peers = [
              # gw0 gateway/router - all traffic routes through gw0
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/gw0/publickey}";
                allowedIPs = [
                  "10.10.10.0/24"
                  "192.168.255.0/24"
                ];
                # Always use remote endpoint through home.mitchty.net... for now
                # need to figure out a way for dynamically swapping to/from
                # internal network peers to not. This is a future me task I got
                # sick of thinking of options
                endpoint = "home.mitchty.net:51820";
                persistentKeepalive = 25;
              }
            ];
            # Enable roaming - automatically switch between local and remote
            # endpoints This doesn't quite work right yet, here to convince me
            # to get off my butt and fix it for macos/nixos
            roaming = {
              localEndpoint = "10.10.10.1:51820";
              remoteEndpoint = "home.mitchty.net:51820";
              detectNetwork = "10.10.10.1"; # Ping gw0 lan ip to detect if we're home
              peerPublicKey = builtins.replaceStrings [ "\n" ] [ "" ] (
                builtins.readFile ../../../crypt/wireguard/gw0/publickey
              );
            };
          };
        };
        shared.mutagen.enable = true;
      };

      networking.hostName = "mbp";

      users.users.mitch.home = "/Users/mitch";

      system = {
        # Don't change nix-darwin stateversion from what things were installed
        # with (unless rebuilding I guess, then do whatever, doesn't matter have
        # backups so nbd either way.
        stateVersion = 5;
        primaryUser = "mitch";
      };

      nixpkgs = {
        overlays = [
          # Expose eca to the package set for emacs
          (import ../../overlays/eca.nix { inherit inputs; })
          # Override the default emacs overlay with macOS support
          (import ../../overlays/emacs.nix { withNs = true; })
        ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";

        users.mitch = {
          # ditto home manager state version generally
          home.stateVersion = "24.11";
          imports = [
            inputs.agenix.homeManagerModules.default
          ]
          ++ (with inputs.self.homeModules; [
            development
            emacs
            gui
            macos
            mutagen
            macos-mitch
            age
            sh
            tmux
            git
            git-age
          ]);

          mitchty.sh.historyBackend = "atuin";
        };
      };
    }
  ];
}
