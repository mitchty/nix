{ inputs, ... }:
{
  system = "x86_64-linux";

  modules = [
    {
      imports =
        (with inputs.self.nixosModules; [
          common
          user-mitch
        ])
        ++ [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
        ]
        ++ [
          ./diskconfig.nix
        ];

      diskConfig.disks = [
        "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
        "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00002"
      ];
      system.stateVersion = "25.05";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-mirror";
    }
  ];
}
# TODO: Maybe yeet ideas from this comment
#https://github.com/nix-community/disko/issues/613#issuecomment-2079307891

# Build a function that can take a string and build a nixosConfiguration that embeds the target nixosConfiguration and installs it in the iso like autoinstall?

# Still need to brain how the heck to get around this infinite recursion error in disko.
