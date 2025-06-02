{ inputs, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
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

      diskConfig.disks = [ "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001" ];
      system.stateVersion = "24.11";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-simple";

      # Disabled for now
      # home-manager.users.mitch.home = {
      #   username = "mitch";
      #   homeDirectory = "/home/mitch";
      #   programs.home-manager.enable = true;
      #   # packages = with pkgs; [
      #   #   # your desired nixpkgs here
      #   # ];
      #   stateVersion = "24.11";
      # };
    }
  ];
}
