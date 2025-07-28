{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    programs = {
      zsh.enable = true;
    };

    users = {
      users.nixos = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        description = "nixos install user";
        shell = pkgs.zsh;
        hashedPassword = lib.mkForce null;
        initialHashedPassword = lib.mkForce null;
        initialPassword = lib.mkForce null;
        password = lib.mkForce null;
        hashedPasswordFile = "${./nixosisopasswd}";
      };
    };
  };
}
