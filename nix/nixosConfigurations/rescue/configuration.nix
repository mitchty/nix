# Build me with nix build .#nixosConfigurations.rescue.config.system.build.isoImage
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
  ]
  ++ (with inputs.self.nixosModules; [
    install-iso
    ssh-nixos
    ssh-root
    iso-zstd-high
  ]);

  environment = {
    systemPackages = [
      pkgs.disko
      pkgs.home-manager
    ];
    variables.EDITOR = "vi";
  };
}
