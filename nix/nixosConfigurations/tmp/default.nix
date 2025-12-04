{
  inputs,
  lib,
  ...
}:
let
  shortHost = "tmp";
  iface = "enp6s0";
  commonMonitoring = {
    enable = true;
    inherit iface;
  };
  system = "x86_64-linux";
in
{
  inherit system;

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
          console-normal
          user-mitch
          user-mitch-compat
          ssh-mitch
          user-root
          ssh-root
          podman
          node-exporter
          promtail
          debug
          virtualization
          power
          power-intel
          gpu-intel
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
        ])
        ++ [
          ./diskconfig.nix
        ];

      # enp88s0/enp91s0 TODO: determine which of these has the built in ilom
      # thing, can maybe use that instead of pikvm for this one node to not have
      # so many pikvms and such.
      services = {
        common.mosh.enable = true;

        mitchty = {
          promtail.enable = true;
          node-exporter = commonMonitoring;
        };
      };

      networking = {
        nameservers = [
          "10.10.10.1"
          #          "1.1.1.1"
        ];
        defaultGateway = {
          address = "10.10.10.1";
          interface = "${iface}";
        };
        # Set the 10g nic up to have a metric cost so this stuff behaves
        # sane...er I hope.
        # dhcpcd.extraConfig = ''
        #   interface enp3s0f1np1
        #   metric 1000
        # '';
        interfaces = {
          "${iface}" = {
            useDHCP = true;
            # ipv4.addresses = [
            #   {
            #     address = "10.10.10.253";
            #     prefixLength = 24;
            #   }
            #   {
            #     address = "10.10.10.224";
            #     prefixLength = 24;
            #   }
            # ];
          };
          # enp3s0f1np1.ipv4 = {
          #   addresses = [
          #     {
          #       address = "10.10.10.252";
          #       prefixLength = 24;
          #     }
          #   ];
          #   routes = [
          #     {
          #       address = "10.10.10.9";
          #       prefixLength = 32;
          #       via = "10.10.10.252";
          #     }
          #   ];
          # };
        };
        # firewall = {
        #   interfaces = {
        #     "${iface}" = {
        #       allowedTCPPorts = [ 3000 ];
        #     };
        #   };
        # };
      };

      # Needed for nixos-hardware common-gpu-nvidia
      # Ref:
      #  Failed assertions:
      # - You must configure `hardware.nvidia.open` on NVIDIA driver versions >= 560.
      # It is suggested to use the open source kernel modules on Turing or later GPUs (RTX series, GTX 16xx), and the closed source modules otherwise.
      #      services.xserver.videoDrivers = [ "nvidia" ];

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T801235B"
        "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T814942M"
      ];
      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        # If this boi needs to build stuff let /tmp be sized enough to build the
        # kernel and some change at 48GiB of rams. The intel box isn't super
        # fast but I'm more abusing it to build iso images and copying stuff
        # directly to the nas over 10g.
        tmp.tmpfsSize = "60%";

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
        kernelParams = [
          "console=tty0"
        ];
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
