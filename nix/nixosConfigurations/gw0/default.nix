{ inputs, lib, ... }:
let
  shortHost = "gw0";
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
          console-normal
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
          power
          power-intel
          nix-offload
          fw
          blocklist
          nix-cache
          router
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
                ]);
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-intel
        ])
        ++ [
          ./diskconfig.nix
        ];

      services = {
        common.mosh.enable = true;

        mitchty = {
          blocklist.enable = true;
          router = {
            enable = true;
            wanIface = "enp4s0";
            lanIface = "br0";
          };
          promtail.enable = true;
          node-exporter = {
            enable = true;
            iface = "br0";
          };
          nixcache = {
            enable = true;
            iface = "br0";
          };
        };
      };

      # Everything here is now in router.nix
      # networking.interfaces = {
      #   enp4s0 = {
      #     useDHCP = true;
      #macAddress = "0c:49:23:0c:0f:0e";
      # };
      # br0 = {
      #   ipv4.addresses = [
      #     {
      #       address = "10.10.10.3";
      #       prefixLength = 24;
      #     }
      #   ];
      # };
      # };

      #      bridges.br0.interfaces = [ "enp4s0" "enp5s0" "enp6s0" ];

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300325L"
        "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300329W"
      ];

      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        # If this boi needs to build stuff let /tmp be sized enough to build the
        # kernel and some change at 48GiB of rams. The intel box isn't super
        # fast but I'm more abusing it to build iso images and copying stuff
        # directly to the nas over 10g.
        tmp.tmpfsSize = "25%";

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

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
