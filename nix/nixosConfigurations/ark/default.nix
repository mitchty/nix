{ inputs, lib, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";

  shortHost = "ark";
in
{
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
          user-root
          user-mitch
          user-mitch-compat
          podman
          #          nas TODO: fix this to work with media as well, will move the base for all media from /nas/media to /nas/srv/media for serving needs
          node-exporter
          {
            services.my.node-exporter = {
              enable = true;
              iface = "enp88s0"; # enp91s0 TODO: determine which of these enables the built in ilom ish thingy
            };
          }
          loki
          {
            services.my.loki = {
              enable = true;
              iface = "enp88s0";
            };
          }
          prometheus
          {
            services.my.prometheus = {
              enable = true;
              iface = "enp88s0";
            };
          }
          grafana
          {
            services.my.grafana = {
              enable = true;
              iface = "enp88s0";
            };
          }
          media
          {
            services.my.media = {
              enable = true;
              services = true;
              iface = "enp88s0";
            };
          }
          debug
          virtualization
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
                imports =
                  [ inputs.agenix.homeManagerModules.default ]
                  ++ (with inputs.self.homeModules; [
                    common
                    sh
                    tmux
                    yt
                    git
                    age
                    debug
                    development
                  ]);
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-intel
          common-gpu-intel
          #          common-gpu-nvidia
        ])
        ++ [
          ./diskconfig.nix
        ];

      networking.interfaces.enp88s0.useDHCP = true;
      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X707714B"
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X700496V"
      ];
      system.stateVersion = "25.05";
      networking.hostName = "ark";

      boot = {
        loader.systemd-boot.enable = true;

        # Had to brain these out from lspci -k and just hulk smashed every
        # module in the chain in here.
        #
        # TODO: since I build my own kernel anyway, why don't I just smash all
        # this crap into a custom defconfig instead there and compile this in
        # not as a module at all?
        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usbhid"
          "usb_storage"
          "sr_mod"
        ];
        kernelModules = [ "kvm-intel" ];
      };

      nixpkgs = {
        hostPlatform = "x86_64-linux";
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            # Both needed for plex
            "plexmediaserver"
            "unrar"

            "nvidia-x11"
            "nvidia-settings"
          ];
      };
    }
  ];
}
