{
  pkgs,
  ...
}:
{
  # Add the xbox one controller package
  environment.systemPackages = [ pkgs.unstable.linuxPackages.xpadneo ];

  services = {
    pulseaudio.support32Bit = true;
  };

  hardware = {
    graphics = {
      extraPackages32 = [ pkgs.pkgsi686Linux.libva ];
      enable32Bit = true;
    };
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
    remotePlay.openFirewall = true;
  };
}
