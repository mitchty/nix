{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  hostName = "ark";
  dependencies = [
    pkgs.stdenv.drvPath
    inputs.self.nixosConfigurations."${hostName}".config.system.build.toplevel
    inputs.self.nixosConfigurations."${hostName}".config.system.build.toplevel.drvPath
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript
    inputs.self.nixosConfigurations."${hostName}".config.system.build.diskoScript.drvPath
    inputs.self.nixosConfigurations."${hostName}".pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.ConfigIniFiles
    inputs.self.nixosConfigurations."${hostName}".pkgs.perlPackages.FileSlurp
  ]
  ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  # # TODO: this is what I originally used keep? Future mitch figure it out sucker.
  # #  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };

  closureInfo = inputs.self.nixosConfigurations."${hostName}".pkgs.closureInfo {
    rootPaths = dependencies;
    #rootPaths = { };
  };

  disk0 = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X707714B";
  disk1 = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X700496V";
  # Badblocks is here to find out if the device might be bad or not, hardware will fail... try to find out at install time.
  autoinstall = pkgs.writeShellScriptBin "autoinstall" ''
     set -eux

     # for disk in ${disk0}; do
     #   ${pkgs.e2fsprogs}/bin/badblocks -wsv $disk
     #   ${pkgs.e2fsprogs}/bin/badblocks -b 4096 -c 1024 -s $disk
     # done
     ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --disk prime ${disk0} --disk m0 ${disk1} --flake "${inputs.self}#${hostName}" "$@"

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
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ]
  ++ (with inputs.self.nixosModules; [
    install-iso
  ]);

  environment = {
    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      autoinstall
      pkgs.disko
      pkgs.home-manager
    ];
  };
}
