{ inputs, ... }:
let
  shortHost = "plx";
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
          user-mitch
          ssh-mitch
          user-root
          ssh-root
          nas
          node-exporter
          {
            services.mitchty.node-exporter = {
              enable = true;
              iface = "enp2s0";
            };
          }
          promtail
          {
            services.mitchty.promtail.enable = true;
          }
          podman
          debug
          fw
        ])
        ++ (with inputs.self.crossplatformModules; [
          mosh
          {
            services.common.mosh.enable = true;
          }
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
                  homeDirectory = "/home/mitch";
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

      # The s100 doesn't have a disk link with a serial number sadly, all I see
      # as links to /dev/sda is:
      # /dev/sda
      # /dev/block/8:0
      # /dev/disk/by-id/scsi-2SAMSUNG
      # /dev/disk/by-path/pci-0000:00:12.7-scsi-0:0:0:0
      # /dev/disk/by-diskseq/12
      #
      # So.... by-id it is I suppose...
      diskConfig.disks = [ "/dev/disk/by-id/scsi-2SAMSUNG" ];
      system.stateVersion = "25.05";
      networking.hostName = "plx";

      boot = {
        loader.systemd-boot.enable = true;

        # Had to brain these out from lspci -k and just hulk smashed every
        # module in the chain in here.
        #
        # TODO: since I build my own kernel anyway, why don't I just smash all
        # this crap into a custom defconfig instead there and compile this in
        # not as a module at all?
        initrd.availableKernelModules = [
          "ufshcd_core"
          "ufshcd_pci"
          "dwc3_pci"
          "usbhid"
          "xhci_pci"
          "ahci"
          "usb_storage"
          "sd_mod"
          "sr_mod"
          "scsi_mod"
          "scsi_common"
          "uas"
        ];
        kernelModules = [ "kvm-intel" ];
        kernelParams = [
          "console=tty0"
        ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
