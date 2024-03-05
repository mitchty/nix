{ config, pkgs, lib, ... }:
with lib;

let
  modules = [ "dm-thin-pool" "dm-cache" ];
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  config = {
    nix = {
      # Cleanup old generations we likely don't need, only on nixos though
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

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

    system.stateVersion = "22.11";

    # BIG TODO: merge the runtime config and this autoinstall setup
    boot.initrd.kernelModules = modules;
    boot.initrd.availableKernelModules = modules;
    boot.kernelModules = modules;

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

    boot.supportedFilesystems = [ "xfs" "zfs" "ext4" ];

    # No docs on the install iso
    documentation.enable = false;
    documentation.nixos.enable = false;

    # Make the default password blank for installation needs, also add pub ssh key.
    users = {
      users.nixos.isNormalUser = true;
      extraUsers = {
        root.openssh.authorizedKeys.keys = [ pubKey ];
        nixos.openssh.authorizedKeys.keys = [ pubKey ];
      };
    };

    # Autologin to the nixos install user on getty
    services.getty.autologinUser = mkForce "root";

    # Let me ssh in by default
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
      };
    };

    # Don't flush to the backing store
    environment.etc."systemd/pstore.conf".text = ''
      [PStore]
      Unlink=no
    '';

    networking = {
      # Don't log failed connections
      firewall.logRefusedConnections = mkDefault false;
      hostName = "autoinstall";

      wireless.enable = false;
      networkmanager.enable = true;
    };

    # I want my magic sysrq triggers to work
    boot.kernel.sysctl = {
      "kernel.sysrq" = 1;
    };

    isoImage = {
      isoName = mkForce "custom.iso";
      squashfsCompression = "zstd -Xcompression-level 6";
    };

    environment = {
      variables = {
        # Since we have no swap, have the heap be a bit less extreme
        GC_INITIAL_HEAP_SIZE = "1M";
      };
    };
    # Give our installer a bit more by default to be more useful.
    environment.systemPackages = with pkgs; [
      btop
      busybox
      coreutils
      curl
      dmidecode
      dropwatch
      flashrom
      iotop
      jq
      linux-firmware
      linuxPackages.cpupower
      linuxPackages.perf
      lvm2
      lvm2.bin
      mdadm
      nixpkgs-fmt
      parted
      pciutils
      powertop
      stdenv
      strace
      tcpdump
      thin-provisioning-tools
      utillinux
      vim
    ];
  };

  options = {
    autoinstall = {
      debug = mkOption {
        type = types.bool;
        default = false;
        description = "If we should exit before installing or not to let debugging occur";
      };
      hostId = mkOption {
        type = types.str;
        default = "auto";
        description = "set hostid manually or autogenerate one (more for zfs)";
      };
      hostName = mkOption {
        type = types.str;
        default = "changeme";
        description = "the hostname the system will be known as";
      };
      rootDevices = mkOption {
        type = types.listOf types.str;
        default = "/dev/sda";
        description = "the root block device that justdoit will nuke from orbit and force nixos onto";
      };
      bootSize = mkOption {
        type = types.str;
        default = "512MiB";
        description = "/boot size";
      };
      swapSize = mkOption {
        type = types.str;
        default = "2GiB";
        description = "swap size";
      };
      osSize = mkOption {
        type = types.str;
        default = "30GiB";
        description = "size of / partition/whatever basically";
      };
      wipe = mkOption {
        type = types.bool;
        default = false;
        description = "run wipefs on devices prior to install";
      };
      zero = mkOption {
        type = types.bool;
        default = false;
        description = "zero out devices prior to install (time consuming)";
      };
      flavor = mkOption {
        type = types.enum [ "single" "zfs" ]; # lvm again? meh
        default = "zfs";
        description = "Specify the disk layout type, single = no zfs mirroring or lvm mirroring";
      };
      typ = mkOption {
        type = types.enum [ "auto" "mirror" "raid5" "raid6" ];
        default = "auto";
        description = ''
          Specify the type of layout to disks, auto tries to do the sanest thing for the flavor in use.

          mirror will just mirror across all devices, <2 devices is fatal
          raidz will setup a raid 5 setup with 1 disk redundancy <2 devices is fatal
          raidz2 does the same but raid 6 with 2 disk redundancy <3 devices is fatal
        '';
      };
    };
  };
  config.systemd.services.autoinstall = {
    description = "NixOS Autoinstall";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "polkit.service" ];
    path = with pkgs; [
      "/run/current-system/sw/"
      "/usr/bin/"
      "${systemd}/bin/"
    ];
    script = with pkgs; (builtins.readFile ./autoinstall.sh);
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
      LIBSH = "${./lib.sh}:${../../static/src/lib.sh}";
      disks = "${toString config.autoinstall.rootDevices}";
      wipe = "${toString config.autoinstall.wipe}";
      zero = "${toString config.autoinstall.zero}";
      debug = "${toString config.autoinstall.debug}";
      bootsize = "${config.autoinstall.bootSize}";
      swapsize = "${config.autoinstall.swapSize}";
      ossize = "${config.autoinstall.osSize}";
      flavor = "${config.autoinstall.flavor}";
      typ = "${config.autoinstall.typ}";
      hostid = "${config.autoinstall.hostId}";
      host = "${config.autoinstall.hostName}";
      configuration = ./configuration.nix;
    };
    serviceConfig = { Type = "oneshot"; };
  };
}
