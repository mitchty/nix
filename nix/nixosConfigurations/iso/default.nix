{ inputs
, lib
, outputs
, ...
}:
let
  sshPubKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
  ];
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

  # inputs.nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #   "broadcom-bt-firmware"
  # ];
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  inherit system;
  modules = [
    ./configuration.nix
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      nixpkgs = {
        config.allowUnfree = true;
        # overlays = [
        #   ../../overlays/altshfmt.nix
        # ];
      };

      networking = {
        hostName = "myiso";
        hostId = "12345678";
      };
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "ca-derivations"
          ];
        };
      };
      services.xserver.enable = lib.mkForce false;
      services.lvm.boot.thin.enable = true;

      # environment.systemPackages = with pkgs; [ altshfmt ];
      hardware = {
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

        # kernelPackages = if (builtins.elem "zfs" bootFilesystems) then pkgs.linuxPackages_latest.zfsStable else pkgs.linuxPackages_latest;

        supportedFilesystems = lib.mkForce bootFilesystems;

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

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;

      users = {
        mutableUsers = false;
        users.root = {
          password = "rescue";
          openssh.authorizedKeys.keys = sshPubKeys;
        };
        users.nixos = {
          isNormalUser = true;
          openssh.authorizedKeys.keys = sshPubKeys;
        };
      };

      system.activationScripts.nixosUserInit =
        let
          userName = "nixos";
          nixosHomeDir = "/home/" + "${userName}/";
          rootHomeDir = "/root/";
        in
        # TODO: integrate home-manager into the iso setup?
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

      isoImage.squashfsCompression = "zstd";
      system.stateVersion = "24.05";
    }
  ];
}
