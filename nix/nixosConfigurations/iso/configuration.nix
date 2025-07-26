# Build me with nix build .#nixosConfigurations.iso.config.system.build.isoImage
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  sshPubKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
  ];
in
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ]
  ++ (with inputs.self.nixosModules; [ install-iso ]);

  environment = {
    systemPackages = [
      pkgs.disko
      pkgs.home-manager
    ];
    variables.EDITOR = "vi";
  };

  users.users = {
    root.openssh.authorizedKeys.keys = sshPubKeys;
    nixos.openssh.authorizedKeys.keys = sshPubKeys;
  };

  isoImage.squashfsCompression = lib.mkForce "zstd -Xcompression-level 19";
}
