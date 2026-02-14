{ inputs, lib, ... }:
let
  shortHost = "wm2";
  iface = "wlp2s0";
in
{
  system = "x86_64-linux";

  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNzRSDjB8WJHSEepNu2GTrZIgFWprv+wMnX6xbeoD0U";
        tags = [
          "wireguard"
          "wifi"
          "cifs"
          "backup"
          "nixos"
        ];
      };
      # TODO: Ok so to make sure I don't get infinite recursion around these
      # here parts.
      #
      # Need to brain a simple way to approach module imports so that an import
      # only occurs once and only once.
      #
      # I'm thinking the nixosModules will contain everything *but* the imports
      # and then I can just setup the imports here?
      #
      # Exception to this rule is disko, that is in common as an import as
      # everything will have it. Actually that will be the *only* exception to
      # this "rule".
      imports =
        (with inputs.self.nixosModules; [
          common
          user-mitch
          ssh-mitch
          user-root
          ssh-root
          user-mitch-compat
          podman
          node-exporter
          promtail
          debug
          virtualization
          power
          power-intel
          nix-offload
          uhk
          networkmanager-laptop
          gui
          powerjoular
          wiffy
          steam
          gaming
          wireguard
          age
        ])
        ++ (with inputs.self.crossplatformModules; [
          common
          mosh
        ])
        ++ [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              users.mitch = {
                home = {
                  username = "mitch";
                  homeDirectory = "/Users/mitch";
                  stateVersion = "25.05";
                };
                imports = [
                  inputs.agenix.homeManagerModules.default
                ]
                ++ (with inputs.self.homeModules; [
                  common
                  sh
                  tmux
                  git
                  age
                  debug
                  # linux-i3
                  # linux-sway - now configured via services.mitchty.gui.windowManager
                  firefox
                  emacs
                ]);

                mitchty.sh.historyBackend = "atuin";
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc-laptop
          common-pc-laptop-ssd
          common-cpu-amd
          common-gpu-amd
          gpd-win-max-2-2023
        ])
        ++ [
          ./diskconfig.nix
        ];

      services = {
        common.mosh.enable = true;

        mitchty = {
          age.enable = true;
          wiffy.enable = true;
          gui = {
            enable = true;
            type = "both"; # Enable both X11 and Wayland sessions
            user = "mitch";
          };
          promtail.enable = true;
          node-exporter = {
            enable = true;
            inherit iface;
          };
          wireguard = {
            enable = false;
            role = "client";
            address = [ "192.168.255.2/24" ];
            privateKeyFile = "secrets/wireguard/prv/wm2";
            dns = [ "10.10.10.1" ];
            peers = [
              # gw0 gateway/router
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/gw0/publickey}";
                allowedIPs = [
                  "10.10.10.0/24" # Home network
                  "192.168.255.0/24" # WireGuard network
                ];
                # Start with remote endpoint, roaming service will switch to local if at home
                endpoint = "home.mitchty.net:51820";
                persistentKeepalive = 25;
              }
            ];
            # Enable roaming - automatically switch between local and remote endpoints
            roaming = {
              localEndpoint = "10.10.10.1:51820"; # Direct LAN when at home
              remoteEndpoint = "home.mitchty.net:51820"; # Through internet when away
              detectNetwork = "10.10.10.1"; # Ping gw0 to detect if we're home
              peerPublicKey = builtins.replaceStrings [ "\n" ] [ "" ] (
                builtins.readFile ../../../crypt/wireguard/gw0/publickey
              );
            };
          };
        };
      };

      networking = {
        firewall = {
          trustedInterfaces = [
            "eth0"
            "wlp2s0"
          ];
        };
        wireless.enable = false;
        networkmanager = {
          enable = true;
          wifi.powersave = false;
          dns = "dnsmasq";
        };
        interfaces = {
          # ???
          ${iface} = {
            useDHCP = true;
          };
          # This is the usb c thingy
          eth0 = {
            useDHCP = true;
          };
        };
      };

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-CWESR02TBTLCZ-27J-2_511231016041001198"
        "/dev/disk/by-id/nvme-Sabrent_Rocket_Q4_48821081708402"
      ];

      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        # If this boi needs to build stuff let /tmp be sized enough to build the
        # kernel and some change at 48GiB of rams. The intel box isn't super
        # fast but I'm more abusing it to build iso images and copying stuff
        # directly to the nas over 10g.
        #        tmp.tmpfsSize = "25%";

        loader.systemd-boot.enable = true;

        # Had to brain these out from lspci -k and just hulk smashed every
        # module in the chain in here.
        #
        # TODO: since I build my own kernel anyway, why don't I just smash all
        # this crap into a custom defconfig instead there and compile this in
        # not as a module at all?
        initrd.availableKernelModules = [
          "nvme"
          "sd_mod"
          "sdhci_pci"
          "sr_mod"
          "thunderbolt"
          "usb_storage"
          "usbhid"
          "xhci_pci"
        ];
        kernelModules = [ "kvm-amd" ];
      };

      nixpkgs = {
        hostPlatform = "x86_64-linux";
        overlays = [
          # Expose eca to the package set for emacs
          (import ../../overlays/eca.nix { inherit inputs; })
          # Override the default emacs overlay with Wayland support
          (import ../../overlays/emacs.nix { withWayland = true; })
          # Override xdg-desktop-portal-wlr with bleeding-edge version for window sharing
          (final: prev: {
            inherit (final.unstable) xdg-desktop-portal-wlr;
          })
        ];
      };
    }
  ];
}
