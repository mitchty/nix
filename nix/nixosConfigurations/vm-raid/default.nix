{ inputs, ... }:
let
  shortHost = "vm-raid";
in
{
  system = "x86_64-linux";

  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvmcCgF67R0DdVAZ+7iuww0dIejSYBNrmJH75AeKdwZ";
        tags = [
          "cifs"
          "nixos"
        ];
      };

      imports =
        (with inputs.self.nixosModules; [
          common
          user-mitch
          ssh-mitch
          user-root
          ssh-mitch
          user-mitch-compat
          console-vm
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
                  # Simpler this way to sync junk with macos and use stuff like
                  # git worktrees which uses full paths in .git files.
                  # TODO: need a compat type home module
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
                ]);
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
        ])
        ++ [
          ./diskconfig.nix
        ];

      diskConfig.disks = [
        "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
        "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00002"
        "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00004" # 3 is the cdrom/dvd
      ];

      system.stateVersion = "25.05";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-raid";
    }
  ];
}
# TODO: Maybe yeet ideas from this comment
#https://github.com/nix-community/disko/issues/613#issuecomment-2079307891

# Build a function that can take a string and build a nixosConfiguration that embeds the target nixosConfiguration and installs it in the iso like autoinstall?
