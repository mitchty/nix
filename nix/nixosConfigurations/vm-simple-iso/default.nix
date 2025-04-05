{
  system = "x86_64-linux";
  modules = [
    ./../../installer
    ./configuration.nix
    {
      system.stateVersion = "24.11";
      boot.loader.systemd-boot.enable = true;
    }
  ];
}
