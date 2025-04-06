{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  dependencies = [
    pkgs.stdenv.drvPath
    inputs.self.nixosConfigurations.vm-simple.config.system.build.toplevel
    inputs.self.nixosConfigurations.vm-simple.config.system.build.diskoScript
    ./../../..
  ] ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };
in
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  # imports = [
  #   "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  # ];

  environment = {
    variables.EDITOR = "vi";

    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      pkgs.disko
      # TODO: replace --flake with the build toplevel instead?
      (pkgs.writeShellScriptBin "install-nixos-unattended" ''
        set -eux
        exec ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --flake "${./../../..}#vm-simple" --disk prime /dev/sda "$@"
      '')
    ];
  };
}
