{ inputs, ... }:
let
  shortHost = "vm-simple";
in
{
  system = "x86_64-linux";

  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuH9BdXTgFflW0uDF1ytFdgHxIBx0NDrHB4jqCjKhQB";
        tags = [
          "cifs"
          "nixos"
        ];
      };

      imports =
        (with inputs.self.nixosModules; [
          common
          console-vm
          user-mitch
          ssh-mitch
          user-root
          ssh-mitch
          user-mitch-compat
          debug
          #          gui
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

      # services.mitchty.gui.enable = true;

      diskConfig.disks = [ "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001" ];
      system.stateVersion = "25.05";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-simple";
    }
  ];
}
