{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix { })
  ];
  environment.variables.EDITOR = "vi";
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
    };
  };
  boot = {
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "vm.overcommit_memory" = lib.mkForce 1;
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
      grub.memtest86.enable = true;
      systemd-boot.memtest86.enable = true;
    };
  };

  # for normal (smaller)
  #      isoImage.squashfsCompression = "zstd";
  # for testing (faster)
  #  isoImage.squashfsCompression = "lz4";
}
