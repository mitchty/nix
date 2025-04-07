{ inputs
, lib
, pkgs
, self
, ...
}:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
  dependencies = [
    # TODO: get this all to work in an airgap setup, some of the .#nixosconfigname stuff pulls stuff down inputs wise
    pkgs.stdenv.drvPath
    inputs.self.nixosConfigurations.vm-simple.config.system.build.toplevel
    inputs.self.nixosConfigurations.vm-simple.config.system.build.diskoScript
    inputs.self.nixosConfigurations.vm-simple.config.system.build.diskoScript.drvPath
    inputs.self.nixosConfigurations.vm-simple.pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    inputs.self.nixosConfigurations.vm-simple.pkgs.perlPackages.ConfigIniFiles
    inputs.self.nixosConfigurations.vm-simple.pkgs.perlPackages.FileSlurp

    #    (inputs.self.nixosConfigurations.vm-simple.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
    ./../../..
  ] ++ builtins.map (i: i.outPath) (builtins.attrValues inputs);

  # TODO: this is what I originally used
  #  closureInfo = pkgs.closureInfo { rootPaths = dependencies; };

  closureInfo = inputs.self.nixosConfigurations.vm-simple.pkgs.closureInfo {
    rootPaths = dependencies;
  };
in
{
  imports = [
    "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # For max compression (takes way longer to build an image tho)
  isoImage.squashfsCompression = "zstd -Xcompression-level 9";
  # Whilst testing uncomment me
  #isoImage.squashfsCompression = "lz4";

  environment = {
    variables.EDITOR = "vi";

    etc."install-closure".source = "${closureInfo}/store-paths";

    systemPackages = [
      pkgs.disko
      (pkgs.writeShellScriptBin "autoinstall" ''
        set -eux
        exec ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --disk prime /dev/disk/by-id/ata-QEMU_HARDDISK_QM00001 --flake "${inputs.self}#vm-simple" "$@"
      '')
    ];
  };

  nix = {
    settings = {
      substituters = [
        # "http://cache.cluster.home.arpa"
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

  # No docs on the install iso
  documentation.enable = false;
  documentation.nixos.enable = false;

  users = {
    mutableUsers = false;
    users.nixos = {
      isNormalUser = true;
      description = "nixos install user";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];

      # This is a test vm only used to test out disk/install automation. Its not
      # getting out/exposed to the outside world ever.
      # echo nixos | openssl passwd -6 -stdin -salt vmtestsalt
      hashedPassword = "$6$vmtestsalt$RU13pQq.NolDt0ZFHiLVzYNjIdTY1aj43jklM/6hrge1NAIosvc.W16.dLf5CwsSaSlbCg0pqupZdkLQdf0/z0";
    };
    extraUsers = {
      root.openssh.authorizedKeys.keys = [ pubKey ];
      nixos.openssh.authorizedKeys.keys = [ pubKey ];
    };
  };

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

  boot = {
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "kernel.sysrq" = lib.mkForce 1;
    };
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
      # iso uses grub installed system uses systemd-boot
      #      systemd-boot.memtest86.enable = true;
    };
  };

}
