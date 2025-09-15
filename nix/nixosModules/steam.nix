{
  pkgs,
  ...
}:
{
  services = {
    xserver.videoDrivers = [ "nvidia" ];
    pulseaudio.support32Bit = true;
  };

  hardware = {
    graphics = {
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
      ];
      enable32Bit = true;
    };
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
    #    package = [ pkgs.e.steam ];
  };
}
