{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  hostName = "vm-raid";
  dependencies = [
    pkgs.stdenv.drvPath
    inputs.self.nixosConfigurations."${hostName}".config.system.build.toplevel
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript.drvPath
    inputs.self.nixosConfigurations."${hostName}".pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.ConfigIniFiles
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.FileSlurp

    #    (inputs.self.nixosConfigurations."${hostName}".pkgs.closureInfo { rootPaths = [ ]; }).drvPath
  ]
  ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  # TODO: this is what I originally used keep? Future mitch figure it out sucker.
  #  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };

  closureInfo = inputs.self.nixosConfigurations."${hostName}".pkgs.closureInfo {
    rootPaths = dependencies;
  };

  autoinstall = pkgs.writeShellScriptBin "autoinstall" ''
    set -eux
    ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --disk prime /dev/disk/by-id/ata-QEMU_HARDDISK_QM00001 --disk m0 /dev/disk/by-id/ata-QEMU_HARDDISK_QM00002 --disk m1 /dev/disk/by-id/ata-QEMU_HARDDISK_QM00004 --flake "${inputs.self}#${hostName}" "$@"
    ${pkgs.disko}/bin/disko -m mount --flake "${inputs.self}#${hostName}"
    install -m600 ${../../../crypt/ssh/${hostName}/ssh_host_ed25519_key} /mnt/etc/ssh/ssh_host_ed25519_key
    install -m644 ${../../../crypt/ssh/${hostName}}/ssh_host_ed25519_key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub
    install -m600 ${../../../crypt/ssh/${hostName}/ssh_host_rsa_key} /mnt/etc/ssh/ssh_host_rsa_key
    install -m644 ${../../../crypt/ssh/${hostName}}/ssh_host_rsa_key.pub /mnt/etc/ssh/ssh_host_rsa_key.pub
    find /mnt/Users/mitch -type d \( ! -user 1000 -o ! -group 100 \) -exec chown 1000:100 {} \+
    btrfs quota enable /mnt
    btrfs quota enable /mnt/var
    btrfs quota enable /mnt/Users
    ${pkgs.disko}/bin/disko -m unmount --flake "${inputs.self}#${hostName}"
  '';
in
# TODO: still trying to figure out how to get the activation package to auto install at partition/copy time
#    ${pkgs.home-manager}/bin/home-manager switch --flake "${inputs.self}#mitch"
#    ${pkgs.home-manager}/bin/home-manager switch --flake "${inputs.self}#homeModules.mitch"
#    nix run "${inputs.self}#homeConfigurations.mitch.activationPackage"
#    nixos-rebuild switch --flake "${inputs.self}#${hostName}"
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ]
  ++ (with inputs.self.nixosModules; [ install-iso ]);

  environment = {
    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      autoinstall
      pkgs.disko
      pkgs.home-manager
    ];
  };
}
