{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  #  home-manager.users.mitch.home.stateVersion = "24.11";
  system.stateVersion = "24.11";
  boot.loader.systemd-boot.enable = true;
  networking.hostName = "vm-simple";
  # home-manager.users.mitch =

  #   { pkgs, ... }:
  #   {
  #     # home.packages = [
  #     #   pkgs.atool
  #     #   pkgs.httpie
  #     # ];

  #     # The state version is required and should stay at the version you
  #     # originally installed.
  #     home.stateVersion = "24.11";
  #   };

  #  home-manager = {
  # users.mitch = {
  #   # home = {
  #   #   stateVersion = "24.11";
  #   # };
  # };
  #sharedModules = [ ./home.nix ];
  #   users.mitch = inputs.self.homeModules.nixos;
  #  };
}
