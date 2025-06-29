{ inputs, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";

  shortHost = "vm-simple";
in
{
  system = "x86_64-linux";

  modules = [
    {
      imports =
        (with inputs.self.nixosModules; [
          common
          user-mitch
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
          common-cpu-intel
        ])
        ++ [
          ./diskconfig.nix
        ];

      diskConfig.disks = [ "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001" ];
      system.stateVersion = "25.05";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-simple";
    }
  ];
}
