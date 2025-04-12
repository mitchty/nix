{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  hostName = "vm-simple";
  dependencies = [
    pkgs.stdenv.drvPath
    inputs.self.nixosConfigurations."${hostName}".config.system.build.toplevel
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript.drvPath
    inputs.self.nixosConfigurations."${hostName}".pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.ConfigIniFiles
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.FileSlurp

    # TODO: what do I need to include exactly to include all the home-manager derivation?
    #    inputs.self.homeModules
    #    (inputs.self.nixosConfigurations."${hostName}".pkgs.closureInfo { rootPaths = [ ]; }).drvPath
  ] ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  # TODO: this is what I originally used keep? Future mitch figure it out sucker.
  #  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };

  closureInfo = inputs.self.nixosConfigurations."${hostName}".pkgs.closureInfo {
    rootPaths = dependencies;
  };

  autoinstall = pkgs.writeShellScriptBin "autoinstall" ''
    set -eux
    ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --disk prime /dev/disk/by-id/ata-QEMU_HARDDISK_QM00001 --flake "${inputs.self}#${hostName}" "$@"
    exit 1
  '';
in
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ] ++ (with inputs.self.nixosModules; [ install-iso ]);

  environment = {
    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      autoinstall
      pkgs.disko
      pkgs.home-manager
    ];
  };
}
