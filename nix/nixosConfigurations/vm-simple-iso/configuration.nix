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
    inputs.self.nixosConfigurations.vm-simple.config.system.build.diskoScript.drvPath
    inputs.self.nixosConfigurations.vm-simple.pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    inputs.self.nixosConfigurations.vm-simple.pkgs.perlPackages.ConfigIniFiles
    inputs.self.nixosConfigurations.vm-simple.pkgs.perlPackages.FileSlurp

    #    (inputs.self.nixosConfigurations.vm-simple.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
  ] ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  # TODO: this is what I originally used keep? Future mitch figure it out sucker.
  #  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };

  closureInfo = inputs.self.nixosConfigurations.vm-simple.pkgs.closureInfo {
    rootPaths = dependencies;
  };

  autoinstall = pkgs.writeShellScriptBin "autoinstall" ''
    set -eux
    exec ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --disk prime /dev/disk/by-id/ata-QEMU_HARDDISK_QM00001 --flake "${inputs.self}#vm-simple" "$@"
  '';
in
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ] ++ (with inputs.self.nixosModules; [ install-iso ]);

  environment = {
    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      pkgs.disko
      autoinstall
    ];
  };
}
