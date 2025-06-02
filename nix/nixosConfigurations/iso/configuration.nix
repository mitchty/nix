# Build me with nix build .#nixosConfigurations.iso.config.system.build.isoImage
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ] ++ (with inputs.self.nixosModules; [ install-iso ]);

  environment = {
    systemPackages = [
      pkgs.disko
      pkgs.home-manager
    ];
    variables.EDITOR = "vi";
  };
}
