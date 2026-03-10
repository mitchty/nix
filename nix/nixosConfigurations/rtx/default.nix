{
  inputs,
  lib,
  ...
}:
let
  shortHost = "rtx";
  iface = "br0";
  system = "x86_64-linux";

in
{
  inherit system;
  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBaFOFERMbg/d7DHrTBJ7pPKiJhwxFadQZlagalg51/";
        tags = [
          "wireguard"
          "cifs"
          "backup"
          "nixos"
          "iscsi"
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
          #          nas TODO: fix this to work with media as well, will move the base for all media from /nas/media to /nas/srv/media for serving needs
          node-exporter
          promtail
          debug
          virtualization
          iscsi
          power
          uhk
          gui
          powerjoular
          nvidia-hack
          steam
          nas
          # ollama
          llama-swap
          gaming
          wireguard
          harmonia
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
              backupFileExtension = "bak";

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
                  development
                  sh
                  yt
                  tmux
                  git
                  git-age
                  age
                  debug
                  gui
                  linux-i3
                  #                  linux-sway
                  # linux-wayland
                  # linux-plasma
                  # linux-hyprland
                  firefox
                  chrome
                  kopia
                  finance
                  eca
                  # For some reason this is being derived when I wouldn't expect
                  # it to be on nix-darwin. Guard against it being evaluated
                  # when not on a linux host platform until I find a better way,
                  # breaking nix flake check on darwin.
                  #
                  # … while realising the context of path '/nix/store/253k47y97jln0kqnf7yqslicj7d2m10y-mytestedemacsconfig-0.0.0/init.el'

                  # error: a 'x86_64-linux' with features {} is required to build '/nix/store/5yd242axp4syplgdk9kiifpqh6fv22r9-native-comp-driver-options-30.patch.drv', but I am a 'aarch64-darwin' with features {apple-virt, benchmark, big-parallel, ca-derivations, nixos-test}
                  #                  (lib.mkIf inputs.nixpkgs.legacyPackages.${system}.hostPlatform.isLinux emacs)
                  emacs
                ]);

                mitchty.sh.historyBackend = "atuin";
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-amd
          #          common-gpu-amd
          common-gpu-nvidia-nonprime
        ])
        ++ [
          ./diskconfig.nix
        ];

      mitchty.iscsi = {
        enable = true;
        portal = "s1.home.arpa:3260";
        auth = {
          username = "mitch";
          passwordAgeFile = ../../../secrets/iscsi/password.age;
        };
        mounts = [
          {
            target = "iqn.2000-01.com.synology:steam";
            device = "/dev/disk/by-path/ip-10.10.10.9:3260-iscsi-iqn.2000-01.com.synology:steam-lun-1";
            mountPoint = "/Users/mitch/.local/share/Steam";
            fsType = "xfs";
            options = [
              "_netdev"
              "nofail"
            ];
          }
        ];
      };

      services = {
        common.mosh.enable = true;

        mitchty = {
          age.enable = true;
          gui = {
            enable = true;
            type = "both";
            user = "mitch";
          };
          promtail.enable = true;
          node-exporter = {
            inherit iface;
            enable = true;
          };
          harmonia = {
            enable = true;
            port = 5000;
            signKeyPath = builtins.toString ../../../crypt/nix/privatekey;
          };
          # ollama = {
          #   inherit iface;
          #   enable = true;
          #   ip = "10.10.10.220";
          #   cname = "ollama.home.arpa";
          # };
          llama-swap = {
            enable = true;
            ip = "127.0.0.1";
            iface = "br0";
            llamaCpppkg = inputs.self.legacyPackages.${system}.ai-nvidia.llama-cpp;
          };
          wireguard = {
            enable = true;
            role = "client";
            address = [ "192.168.255.5/24" ];
            listenPort = 51820; # Required for peer-to-peer mesh
            privateKeyFile = "secrets/wireguard/prv/rtx";
            dns = [ "10.10.10.1" ];
            peers = [
              # gw0 gateway/router - routes roaming clients through gw0
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/gw0/publickey}";
                allowedIPs = [
                  "192.168.255.1/32" # gw0
                  "192.168.255.6/32" # mbp (roaming)
                  "192.168.255.2/32" # wm2 (roaming)
                ];
                endpoint = "10.10.10.1:51820"; # Always local
                persistentKeepalive = 25;
              }
              # plx (stationary) - direct peer
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/plx/publickey}";
                allowedIPs = [
                  "192.168.255.3/32" # plx
                ];
                endpoint = "10.10.10.14:51820";
                persistentKeepalive = 25;
              }
              # ark (stationary) - direct peer
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/ark/publickey}";
                allowedIPs = [
                  "192.168.255.4/32" # ark
                ];
                endpoint = "10.10.10.253:51820";
                persistentKeepalive = 25;
              }
            ];
          };
        };
      };

      networking = {
        nameservers = [
          "10.10.10.1"
        ];
        defaultGateway = {
          address = "10.10.10.1";
          interface = iface;
        };
        firewall = {
          trustedInterfaces = [
            iface
          ];
        };
        bridges.br0.interfaces = [ "eno1" ];
        wireless.enable = false;
        networkmanager = {
          enable = true;
          wifi.powersave = false;
          #          dns = "dnsmasq";
        };
        interfaces = {
          br0 = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "10.10.10.11";
                prefixLength = 24;
              }
            ];
          };
          eno1.useDHCP = false;
          eno2.useDHCP = false;
        };
      };

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X201453Y"
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X207489F"
      ];

      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        kernelParams = [
          "usbcore.autosuspend=-1"
        ];
        loader = {
          systemd-boot = {
            enable = true;
            memtest86.enable = true;

            # /boots only a gig, too many copied initrd/etc.. kernels leads to
            # full fs... maybe I shouldn't always follow the latest kernels so
            # much..
            configurationLimit = 10;

            # efi = {
            #   canTouchEfiVariables = true;
            #   efiSysMountPoint = "/boot";
            # };

            # TODO: make a systemd-boot mirroring module for nixos
            # configurationLimit = 20;
            #          generationsDir.copyKernels = true;
            # Loop through all the /bootN vfat filesystems after kernels are
            # installed to the primary efi system mountpoint and rsync em over
            # to the rest of the /boot mounts
            #
            # Then voila, we can boot off the other devices magically. Its a
            # hack but its... fine. I give up on trying to convince an md mirror
            # of this crap to work.

            # extraInstallCommands = ''
            #   set -e
            #   for mnt in $(df -t vfat | awk '/\/boot[0-9]+/ {print $6}'); do
            #     ${pkgs.rsync}/bin/rsync -Havzn --checksum --exclude .lost+found --delete --delete-before /boot $mnt
            #   done
            # '';
          };
        };
        tmp = {
          cleanOnBoot = true;
          useTmpfs = true;
          # Compiling the linux kernel takes at least 20GiB, so set it
          # to 32GiB for when I'm mobile and compiling sized higher
          # cause the effing rocm driver compilation takes like 34GiB,
          # sigh... I need a laptop with 128GiB of rams apparently.
          #
          # Stupid ollama derivations and amd driver shenanigans BOO
          # URNS I say.
          #
          # Ungh so if I get like two electron app builds at once poof 70G of
          # /tmp gone away.
          tmpfsSize = "70%";
        };

        # If this boi needs to build stuff let /tmp be sized enough to build the
        # kernel and some change at 48GiB of rams. The intel box isn't super
        # fast but I'm more abusing it to build iso images and copying stuff
        # directly to the nas over 10g.
        #        tmp.tmpfsSize = "25%";

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

      hardware = {
        enableRedistributableFirmware = true;
        nvidia = {
          open = lib.mkForce true;
          nvidiaSettings = true;
          modesetting.enable = true;
          powerManagement.enable = true;
        };
      };

      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = "x86_64-linux";
        overlays = [
          # Expose eca to the package set for emacs
          (import ../../overlays/eca.nix { inherit inputs; })
          # Override the default emacs overlay with Wayland support
          (import ../../overlays/emacs.nix {
            withWayland = true;
            withX = false;
          })
          # (import ../../overlays/emacs.nix { withX = true; })
        ];
      };
    }
  ];
}
