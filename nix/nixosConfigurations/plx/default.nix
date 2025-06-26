{ inputs, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
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
        [
          inputs.agenix.nixosModules.default
        ]
        ++ (with inputs.self.nixosModules; [
          common
          user-mitch
          nas
          node-exporter
          podman
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
                  #   #        programs.home-manager.enable = true;

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

      services.node-exporter = {
        enable = true;
        exporterIface = "enp2s0";
      };

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
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
