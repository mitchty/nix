{
  inputs,
  lib,
  ...
}:
let
  shortHost = "rtx";
in
rec {
  system = "x86_64-linux";

  modules = [
    {
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
          power
          uhk
          gui
          nvidia-hack
          steam
          nas
          ai
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
                  development
                  sh
                  yt
                  tmux
                  git
                  git-age
                  age
                  debug
                  #                  linux-i3
                  linux-sway
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

      services = {
        common.mosh.enable = true;

        mitchty = {
          gui = {
            enable = true;
            type = "wayland";
          };
          promtail.enable = true;
          node-exporter = {
            enable = true;
            iface = "br0";
          };
          ai.enable = true;
        };
      };

      networking = {
        nameservers = [
          "10.10.10.1"
        ];
        defaultGateway = {
          address = "10.10.10.1";
          interface = "br0";
        };
        firewall = {
          trustedInterfaces = [
            "br0"
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
        hosts = {
          "10.200.200.254" = [
            "vip.dev.home.arpa"
          ];
          "10.200.200.253" = [
            "demo.dev.home.arpa"
            "ai.dev.home.arpa"
          ];
          "10.200.200.252" = [
            "misc.dev.home.arpa"
          ];
        };
      };

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X201453Y"
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X207489F"
      ];

      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            memtest86.enable = true;
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

      hardware.enableRedistributableFirmware = true;
      hardware.nvidia = {
        open = lib.mkForce true;
        nvidiaSettings = true;
        modesetting.enable = true;
        powerManagement.enable = true;

        # This kinda craps in nvidia-hack now rest is "normal" settings
        # package = pkgs.kernelPackages.nvidiaPackages.mkDriver {
        #   version = "570.181";
        #   sha256_64bit = "sha256-8G0lzj8YAupQetpLXcRrPCyLOFA9tvaPPvAWurjj3Pk=";
        #   sha256_aarch64 = "sha256-1pUDdSm45uIhg0HEhfhak9XT/IE/XUVbdtrcpabZ3KU=";
        #   openSha256 = "sha256-U/uqAhf83W/mns/7b2cU26B7JRMoBfQ3V6HiYEI5J48=";
        #   settingsSha256 = "sha256-iBx/X3c+1NSNmG+11xvGyvxYSMbVprijpzySFeQVBzs=";
        #   persistencedSha256 = "sha256-RoAcutBf5dTKdAfkxDPtMsktFVQt5uPIPtkAkboQwcQ=";
        # };
      };

      nixpkgs = {
        config = {
          allowUnfree = true;
        };
        #        config.cudaSupport = true;
        hostPlatform = "x86_64-linux";
      };
    }
  ];
}
