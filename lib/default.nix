{ self
, pkgs
, lib
, ...
}:
# Helper util functions for the rest of the flake. LOTS TO DO HERE!
let
  # Note, no label/partlables allowed as those aren't "stable" in regards to
  # paths. This function requires true stability/immutability vs "whatever the label with string xyz" was setup as.
  assertStablePath = x: assert ((lib.strings.hasPrefix "/dev/disk/by-id/" x) || (lib.strings.hasPrefix "/dev/disk/by-uuid/" x) || abort "block device path '${x}' must be a path using /dev/disk/by-id/ or /dev/disk/by-uuid/ for stable device path configuration"); x;
  diskoConfig = devices: lib.trace {
    disk = {
      disk1 = {
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "boot";
              start = "0";
              end = "1M";
              part-type = "primary";
              flags = [ "bios_grub" ];
            }
            {
              name = "ESP";
              start = "1M";
              end = "1G";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "zfsroot";
              start = "1G";
              end = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            }
          ];
        };
      };
      sshPubKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
      ];

      installIsoSystem = system: lib.nixosSystem {
        inherit system;
        modules = [
          ({ lib
           , modulesPath
           , pkgs
           , ...
           }: {
            imports = [
              # Build on top of the GNOME installer ISO
              "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
              "${modulesPath}/installer/cd-dvd/channel.nix"
              #            ../modules/nixos
            ];

            nix = {
              settings = {
                substituters = [
                  "http://cache.cluster.home.arpa"
                  "https://cache.nixos.org"
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };

              # Lets things download in parallel
              extraOptions = ''
                binary-caches-parallel-connections = 100
                experimental-features = nix-command flakes
              '';
            };

            services.lvm.boot.thin.enable = true;

            boot.kernelParams = [
              "boot.shell_on_fail"
              "console=ttyS0,115200n8"
              "copytoram=1"
              "delayacct"
              "intel-spi.writeable=1"
              "iomem=relaxed"
            ];
            boot.loader.grub.extraConfig = "
            serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
            terminal_input serial
            terminal_output serial
          ";

            documentation.enable = false;
            documentation.nixos.enable = false;

            isoImage.isoBaseName = "nixos-rescue";

            system.stateVersion = "23.11";
            time.timeZone = "America/Central";

            networking.hostId = lib.mkForce "12345678";
            # Use latest kernel
            # boot.kernelPackages = pkgs.linuxPackages_latest;

            boot.supportedFilesystems = lib.mkForce [
              "btrfs"
              "cifs"
              "exfat"
              "ext2"
              "ext4"
              "f2fs"
              "jfs"
              "ntfs"
              "reiserfs"
              "vfat"
              "xfs"
              "zfs"
            ];
            # networking.hostId = null;

            # Support building for other linux systems supported by this flake
            # boot.binfmt.emulatedSystems =
            #   builtins.filter
            #     (supportedSystem: supportedSystem != system && linuxSystem supportedSystem pkgs)
            #     config.systems;

            networking = {
              hostName = "rescue";
              wireless = {
                enable = true;
                userControlled.enable = true;
              };
            };

            # Add additional rescue tools
            environment.systemPackages = with pkgs; [
              coreutils
              efitools
              fd
              file
              inetutils
              jq
              lsof
              neovim
              ripgrep
              wget
            ];

            programs.zsh.enable = true;
            environment.shells = [ pkgs.zsh ];
            users.defaultUserShell = pkgs.zsh;

            users = {
              mutableUsers = false;
              users.root.password = "rescue";
              users.nixos.isNormalUser = true;
              # [
              #     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
              #   ];
              # extraUsers = {
              #   root.openssh.authorizedKeys.keys = [ sshPubKey ];
              #   nixos.openssh.authorizedKeys.keys = [ sshPubKey ];
              # };
            };

            # # Define root user
            # users.users.root = {
            #   password = "rescue";
            #   # openssh.authorizedKeys.keys = inputs.self.lib.mySshKeys;
            # };
            # users.mutableUsers = false;
          })
        ];
      };
      in
      { }
