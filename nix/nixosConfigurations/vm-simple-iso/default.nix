{
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    {
      system.stateVersion = "25.05";
      boot.loader.systemd-boot.enable = true;
    }
  ];
}
