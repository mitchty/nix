/*
  Functions that take a nixosConfiguration and disko layout and install nixos.
  Intended for automatic (re)installation of a nixos system based off of an
  existing nixosConfiguration.

  TODO: enable passing in existing ssh hostkeys for the resulting nixos derivation so that things like age decryption works post boot.

  Note, this is highly opinionated for now in what layouts it produces. That is,
  efi only layouts, how they are laid out etc...

  My point of view for this is this is all how I setup things myself, I'm not
  trying to boil the ocean in allowing "everything" that could be allowed.

  Therefore, everything here conforms to:
  - efi only, no legacy bios
  - no more grub due to ^^^
  - using systemd-boot like ye olde lilo days of yore

  TODO: encryption setup(s) for zfs/md/etc..?

  I do need encryption for mobile devices. Maybe use zfs native encryption for
  root zpool(s) and luks for non? Future me problem.

  Tranche 0:
  - A hack one disk layout for vm setups with straight up raw xfs filesystems.

  Note the top level autoinstaller function is intended to produce an isoImage from some existing nixosConfiguration to make ci easierish...

  Other advantage here is I can produce iso images I can then use on vps
  providers directly to boot straight into setups and not worry if they
  "support" nixos. Given most are simply kvm underneath abusing /dev/vdaN or
  /dev/sdaN should be fine in those setups. But for now I'm forcing
  /dev/disk/by-{uuid,id} strings for setups to ensure this autoinstaller fails
  if its ran on the wrong system(s) somehow.

  For now this also is 1:1 config->iso mapping setup. I might consider trying to
  have a single iso derivation with multiple input derivations at some point.
  Also a future me problem for a future winter to solve if at all. Though that
  might help with testing nixos version upgrades too in vm's. Something to
  ponder.

  Also note, the input nixosConfiguration doesn't need its own disko setup for now.
*/

{ disko
, ...
}: {
  /*  Creates a shell script that will:

        1. Make and partition ZFS on a given block device
        2. nixos-install a given nixosConfiguration to it
        3. `umount` and `zpool export` the pool.

        This function will also attempt to clean the nixosConfiguration by
        removing machine-specific details such as filesystems,
        networking.interfaces.

        This function does not require the given nixosConfiguration to have a
        disko configuration, as it will force an opinionated one in. This is
        only intended for one-time stateless setups where you do not intend to
        run a nixos-rebuild switch on the machine that results from this
        function.

        Type: mkOpinionatedZfsNuke :: nixosConfiguration -> str -> derivation

        Example:
          mkOpinionatedZfsNuke self.nixosConfigurations.myMachine "/dev/sda"
          => derivation
    */

  mkSimpleLayout = nixosConfiguration: device:
    let
      inherit (nixosConfiguration) pkgs;

      cleanedConfiguration = nixosConfiguration.extendModules {
        modules = [
          {
            fileSystems = pkgs.lib.mkOverride 50 { };
            networking.interfaces = pkgs.lib.mkOverride 50 { };
            boot.initrd.luks.devices = pkgs.lib.mkOverride 50 { };
          }
        ];
      };
      extendedConfiguration = cleanedConfiguration.extendModules {
        modules = [
          disko.nixosModules.default
          ./simple.nix
        ];
        specialArgs = {
          inherit device;
        };
      };
      finalConfiguration = extendedConfiguration.extendModules {
        modules = [
          ({ config, ... }: pkgs.lib.mkForce (pkgs.lib.mkMerge (disko.lib.lib.config extendedConfiguration.config.disko.devices)))
        ];
      };
    in
    pkgs.writeShellScriptBin "diskoScript" ''
      ${finalConfiguration.config.system.build.diskoScript}
      nixos-install --no-root-password --option substituters "" --no-channel-copy --system ${finalConfiguration.config.system.build.toplevel}
      umount -R '${finalConfiguration.config.disko.rootMountPoint}'
    '';

  /*  Creates a shell script that will:

        1. Make and partition ZFS on a given block device
        2. nixos-install a given nixosConfiguration to it
        3. `umount` and `zpool export` the pool.

        This function requires that a disko configuration with a zpool is
        already present inside of the given nixosConfiguration.

        Type: mkZfsNuke :: nixosConfiguration -> str -> derivation

        Example:
          mkZfsNuke self.nixosConfigurations.myMachine "/dev/sda"
          => derivation
    */

  mkZfsNuke = nixosConfiguration: device:
    let
      inherit (nixosConfiguration) pkgs;
    in
    pkgs.writeShellScriptBin "install-${nixosConfiguration.config.system.name}-to-${device}" ''
            ${nixosConfiguration.config.system.build.diskoScript}
            nixos-install --no-root-password --option substituters "" --no-channel-copy --system ${nixosConfiguration.config.system.build.toplevel}
            umount -R '${nixosConfiguration.config.disko.rootMountPoint}'
      #      zpool export '${toString (builtins.attrNames nixosConfiguration.config.disko.devices.zpool)}'
    '';

  /*  Creates a NixOS installer iso that contains the toplevel from the given
        nixosConfiguration in the closure. This installer will then runs the
        diskoScript from a given nixosConfiguration on boot, install the
        toplevel via nixos-install and reboot

        This function requires that a disko configuration is already present
        inside of the given nixosConfiguration.

        Type: mkAutoInstaller :: nixosConfiguration -> derivation

        Example:
          mkAutoInstaller self.nixosConfigurations.myMachine
          => derivation
    */

  mkAutoInstallIso = nixosConfiguration:
    let
      inherit (nixosConfiguration) pkgs;
      nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";
    in
    nixosSystem {
      inherit (pkgs) system;
      modules = [
        "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
        {
          isoImage.forceTextMode = true;
          isoImage.squashfsCompression = "zstd -Xcompression-level 1";
          services.getty.autologinUser = pkgs.lib.mkForce "root";
          environment.systemPackages = [
            (pkgs.writeShellScriptBin "diskoScript" ''
              ${nixosConfiguration.config.system.build.diskoScript}
              nixos-install --no-root-password --option substituters "" --no-channel-copy --system ${nixosConfiguration.config.system.build.toplevel}
              echo reboot
            '')
          ];
          programs.bash.interactiveShellInit = ''
            if [ "$(tty)" = "/dev/tty1" ]; then
              diskoScript
            fi
          '';
        }
      ];
    };
}
