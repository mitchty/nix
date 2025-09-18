# Common boot params, boot.tmp.tmpfsSize is a candidate for not being here
{ pkgs, lib, ... }:
{
  environment = {
    systemPackages = [
      pkgs.efibootmgr
    ];
  };

  boot = {
    tmp = {
      cleanOnBoot = true;
      useTmpfs = true;
      tmpfsSize = lib.mkDefault "10%";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "vm.overcommit_memory" = lib.mkDefault "1";
    };

    kernelParams = [
      "boot.shell_on_fail"
      #"console=ttyS0,115200n8"
      #              "console=tty0" # fallback somehow if serial no work somehow?
      "delayacct"
      "intel-spi.writeable=1"
      "iomem=relaxed"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      # iso uses grub installed system uses systemd-boot
      systemd-boot.memtest86.enable = true;
    };
  };

  hardware.mcelog.enable = true;
}
