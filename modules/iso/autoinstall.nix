{ config, pkgs, lib, ... }:
with lib;

let
  modules = [ "dm-thin-pool" "dm-cache" ];
  autoinstallsh = (pkgs.writeScriptBin "autoinstall" (builtins.readFile ./autoinstall.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  config = {
    system.stateVersion = "22.05";

    # BIG TODO: merge the runtime config and this autoinstall setup
    boot.initrd.kernelModules = modules;
    boot.initrd.availableKernelModules = modules;
    boot.kernelModules = modules;

    services.lvm.boot.thin.enable = true;

    boot.kernelParams = [ "boot.shell_on_fail" "console=ttyS0,115200" "console=tty0" "iomem=relaxed" "intel-spi.writeable=1" "delayacct" ];
    boot.loader.grub.extraConfig = "
      serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
      terminal_input serial
      terminal_output serial
    ";

    # boot.kernelPackages = pkgs.linuxPackages_latest;

    # kernelPatches = pkgs.lib.singleton {
    #   name = "Custom extra kernel config + maybe patches at some point";
    #   patch = null;
    #   # The default nixpkgs kernel has these as modules, but whatever just
    #   # compile them in statically
    #   extraConfig = ''
    #      DM_CACHE m
    #      DM_INTEGRITY m
    #      DM_VERITY m
    #      DM_THIN_PROVISIONING m
    #   '';
    # };

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
      permitRootLogin = "yes";
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
    };

    # I want my magic sysrq triggers to work
    boot.kernel.sysctl = {
      "kernel.sysrq" = 1;
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
      iotop
      jq
      linuxPackages.cpupower
      linuxPackages.perf
      flashrom
      lvm2
      lvm2.bin
      mdadm
      parted
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
        default = "10GiB";
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
      dedicatedBoot = mkOption {
        type = types.str;
        default = "";
        description = "If there should be a dedicated /boot device fill this in with the device name.";
      };
      # Needs a lot more testing somehow, vm's?
      flavor = mkOption {
        type = types.enum [ "single" "zfs" "lvm" ];
        default = "zfs";
        description = "Specify the disk layout type, single = no zfs mirroring or lvm mirroring";
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
      disks = "${config.autoinstall.dedicatedBoot} ${toString config.autoinstall.rootDevices}";
      wipe = "${toString config.autoinstall.wipe}";
      zero = "${toString config.autoinstall.zero}";
      flavor = "${config.autoinstall.flavor}";
      debug = "${toString config.autoinstall.debug}";
      dedicatedboot = "${config.autoinstall.dedicatedBoot}";
      bootsize = "${config.autoinstall.bootSize}";
      swapsize = "${config.autoinstall.swapSize}";
      ossize = "${config.autoinstall.osSize}";
      host = "${config.autoinstall.hostName}";
      configuration = ./configuration.nix;
    };
    serviceConfig = { Type = "oneshot"; };
  };
}
