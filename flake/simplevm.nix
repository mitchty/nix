# { self, pkgs, ... }:
# let
#   inherit (self.inputs) nixos-generators;
#   defaultModule = {
#     imports = [
#       ../modules/iso/autoinstall.nix
#     ];
#     _module.args.inputs = self.inputs;
#   };

#   onLinux = system: builtins.elem system pkgs.lib.systems.doubles.linux;
# in
# {
#   perSystem =
#     { pkgs
#     , system
#     , ...
#     }:
#     {

#       mkIf (onLinux system) {
#       packages.install-iso = nixos-generators.nixosGenerate {
#         inherit pkgs system;
#         modules = [
#           defaultModule
#           {
#             autoinstall = {
#               flavor = "single";
#               hostName = "simple";
#               rootDevices = [
#                 "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"
#               ];
#               bootSize = "512MiB";
#               swapSize = "16GiB";
#               osSize = "20GiB";
#               debug = true;
#             };
#           }
#         ];
#         format = "install-iso";
#       };
#     }
#     }

# This part defines a NixOS rescue/installation ISO that can be used to bootstrap or repair systems.
{ config
, inputs
, ...
}:
let
  #  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";

  inherit (inputs) nixpkgs;

  inherit (nixpkgs.lib) mkIf nixosSystem;

  pkgs = import inputs.nixpkgs;

  #  inherit (nixpkgs.stdenv.hostPlatform) isLinux;
  #  ailib = ../lib/autoinstaller;

  # inherit (mylib) installIsoSystem linuxSystem sshPubKey;

  # Include more fs types than the target nixosconfig might have
  bootFilesystems = [
    "btrfs"
    "cifs"
    "exfat"
    "ext2"
    "ext4"
    "f2fs"
    "ntfs"
    "vfat"
    "xfs"
    # "zfs"
    #"bcachefs"
  ];

  simplevmConfig = system:
    inputs.nixpkgs.lib.nixosSystem rec {
      format = "install-iso";
      inherit system;
      modules = [
        #        inputs.disko.nixosModules.disko
        ({ lib
         , modulesPath
         , pkgs
         , ...
         }: rec {
          imports = [
            # Build on top of the minimal installer derivation, gooeys are lame af
            # text4eva.
            "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
            "${modulesPath}/installer/cd-dvd/channel.nix"
            #            inputs.disko.nixosModules.default
            ./diskotest.nix

            #            ../modules/nixos
            # ../lib/autoinstall/simple.nix
            # { device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001"; }
          ];

          # mostly for the firmware really.
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            # self.overlays.defaults
            # self.overlays.development
            # self.overlays.inputs
            # self.overlays.emacs
            # self.overlays.personal
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
              binary-caches-parallel-connections = 20
              experimental-features = nix-command flakes
            '';
          };

          services.xserver.enable = lib.mkForce false;
          services.lvm.boot.thin.enable = true;

          hardware = {
            # make this installer agnostic to intel/amd differences
            cpu.intel.updateMicrocode = true;
            cpu.amd.updateMicrocode = true;

            enableAllFirmware = true;
            bluetooth = {
              enable = true;
              powerOnBoot = false;
            };
          };

          boot = {
            # I want my magic sysrq triggers to work
            kernel.sysctl = {
              "kernel.sysrq" = 1;
              "vm.overcommit_memory" = lib.mkForce 1;
            };

            # Use latest kernel if zfs isn't in the supported fs list, otherwise
            # latest zfs compatible kernel.
            kernelPackages = if (builtins.elem "zfs" bootFilesystems) then pkgs.linuxPackages_latest.zfsStable else pkgs.linuxPackages_latest;

            # kernelPackages = pkgs.linuxPackages_latest;
            kernelParams = [
              "boot.shell_on_fail"
              "console=ttyS0,115200n8"
              #              "console=tty0" # fallback somehow if serial no work somehow?
              "copytoram=1"
              "delayacct"
              "intel-spi.writeable=1"
              "iomem=relaxed"
            ];

            # extraModulePackages = with config.boot.kernelPackages; [
            #   acpi_call
            #   chipsec
            # ];

            supportedFilesystems = lib.mkForce bootFilesystems;

            # Note: grub here is just for the iso itself, grub is not being used
            # for the things that are built any longer.
            # boot.loader.grub.extraConfig = "
            #   serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
            #   terminal_input serial
            #   terminal_output serial
            # ";

            loader = {
              efi = {
                canTouchEfiVariables = true;
              };
              grub.memtest86.enable = true;
              # systemd-boot = {
              #   enable = true;
              #   memtest86.enable = true;
              # };
            };
          };

          # documentation.doc.enable = lib.mkForce false;
          # documentation.enable = lib.mkForce false;

          # iso image name to distinguish things and slightly better compression
          # for the squashfs image

          isoImage = {
            forceTextMode = true;
            makeEfiBootable = true;
            makeUsbBootable = true;
            # isoName = "nixos-${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
            isoBaseName = "simplevm";
            squashfsCompression = "zstd -Xcompression-level 22";
          };

          system.stateVersion = "23.11";
          time.timeZone = "America/Central";

          # only need hostid for zfs support really
          networking.hostId = lib.mkForce
            "12345678";
          # Use latest kernel


          # boot.kernelPackages = if (builtins.elem "zfs" self.boot.supportedFilesystems) then pkgs.latestCompatibleLinuxPackages else pkgs.linuxPackages_latest;

          # networking.hostId = null;

          # Support building for other linux systems supported by this flake
          # boot.binfmt.emulatedSystems =
          #   builtins.filter
          #     (supportedSystem: supportedSystem != system && linuxSystem supportedSystem)
          #     config.systems;

          networking = {
            hostName = "simplevm";
            firewall.logRefusedConnections = lib.mkDefault false;
            wireless = {
              enable = true;
              userControlled.enable = true;
            };
          };

          # Let me ssh in by default and to root for ez debugging
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "yes";
            };
          };

          programs.zsh.enable = true;
          environment = {
            # Don't flush to the backing store for things that shouldn't be written to often.
            etc."systemd/pstore.conf".text = ''
              [PStore]
              Unlink=no
            '';

            shells = [ pkgs.zsh ];
            variables = {
              # Since we have no swap, have the heap be a bit less extreme so nix commands don't use obscene amounts of ram
              GC_INITIAL_HEAP_SIZE = "1M";
            };
            # All the "extra" nonsense I might want to use to debug stuff with
            # live or not.
            systemPackages = with pkgs; [
              (writeShellScriptBin "nixos-autoinstall" ''
                set -eux

                echo autoinstall or whatever
              '')
              # (writeShellScriptBin "nixos-autoinstall" ''
              #   set -eux

              #   echo ${system.build.diskoScript} --mode zap_create_mount

              #   echo ${system.build.nixos-install}/bin/nixos-install \
              #       --root /mnt \
              #       --no-root-passwd \
              #       --no-channel-copy \
              #       --system ${system.build.toplevel}

              #   sync

              #   echo ${systemd}/bin/shutdown now
              # '')
              # (pkgs.writeShellScriptBin "disko-install" ''
              #   ${config.system.build.diskoScript}
              #   echo nixos-install --no-root-password --option substituters "" --no-channel-copy --system ${config.system.build.toplevel}
              #   echo reboot
              # '')
              # altshfmt
              # transcrypt
              # asm-lsp
              # hatools
              #		sshfs-fuse
              bind
              btop
              btrfs-progs
              busybox
              bzip2
              ccrypt
              chipsec
              coreboot-utils
              coreutils
              cryptsetup
              curl
              ddrescue
              devmem2
              dmidecode
              dosfstools
              dropwatch
              e2fsprogs
              efibootmgr
              efitools
              efivar
              exfat
              f2fs-tools
              fd
              file
              flashrom
              gitAndTools.gitFull
              gptfdisk
              gzip
              hdparm
              hexdump
              htop
              i2c-tools
              inetutils
              intel-gpu-tools
              iotools
              iotop
              jfsutils
              jq
              jq
              linux-firmware
              linuxPackages.cpupower
              linuxPackages.perf
              lm_sensors
              lsof
              lvm2
              lvm2.bin
              mdadm
              mkpasswd
              ms-sys
              msr-tools
              nixos-install-tools
              ntfsprogs
              nvme-cli
              openssl
              p7zip
              parted
              pcimem
              pciutils
              powertop
              psmisc
              ripgrep
              rsync
              sdparm
              smartmontools
              socat
              stdenv
              strace
              tcpdump
              thin-provisioning-tools
              unzip
              usbutils
              utillinux
              vim
              wget
              zip
              zstd
            ];
          };
          users.defaultUserShell = pkgs.zsh;

          users = {
            mutableUsers = false;
            users.root = {
              password = "rescue";
              openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
              ];
              # openssh.authorizedKeys.keys = sshPubKeys;
            };
            users.nixos = {
              isNormalUser = true;
              # openssh.authorizedKeys.keys = sshPubKeys;
            };
          };

          system.activationScripts.nixosUserInit =
            let
              userName = "nixos";
              nixosHomeDir = "/home/" + "${userName}/";
              rootHomeDir = "/root/";
            in
            # TODO: integrate home-manager into the iso setup maybe future me?
              #
              # This is just a quick hack to setup .zshrc/history in case I
              # need/want to ssh in to debug I can have a prepopulated history
              # of likely crap to run.
            ''
              for x in ${rootHomeDir} ${nixosHomeDir}; do
              touch $x/.zshrc

              cat >> $x/.zshrc << 'FIN'
              set -o emacs
              asroot() {
                if [ "$(id -u)" -ne 0 ]; then
                  sudo "$@"
                else
                  "$@"
                fi
              }
              FIN

              if ! grep -q sysrq-trigger $x/.zsh_history; then
                cat >> $x/.zsh_history << FIN
              asroot systemctl reboot --firmware-setup
              echo b | asroot tee /proc/sysrq-trigger
              echo o | asroot tee /proc/sysrq-trigger
              asroot systemctl restart autoinstall
              asroot systemctl status autoinstall
              touch /tmp/okgo
              touch /tmp/wait
              asroot sudo shutdown now
              journalctl -u autoinstall | cat
              journalctl -fu autoinstall
              FIN
              fi
              done
              chown nixos:users ${nixosHomeDir}/.zsh_history ${nixosHomeDir}/.zshrc
            '';

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
{
  # flake.nixosConfigurations.rescue = installIsoSystem "x86_64-linux" nixpkgs config;

  perSystem = { system, pkgs, ... }:
    # mkIf (linuxSystem system) {
    mkIf pkgs.hostPlatform.isLinux {
      # packages.rescueIso = (installIsoSystem system).config.system.build.isoImage;
      packages.simplevmIso = (simplevmConfig system).config.system.build.isoImage;
    };
}
