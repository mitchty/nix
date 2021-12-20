{ pkgs, ... }: {
  # TODO: can home-manager sort this out now?
  # My normal user account
  users.users.mitch = {
    isNormalUser = true;
    description = "Mitchell James Tishmack";
    home = "/home/mitch";
    createHome = true;
    shell = pkgs.zsh;
    initialPassword = "changeme";
    extraGroups = [
      "audio"
      "docker"
      "jackaudio"
      "libvirtd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  # TODO: figure this out
  # Only what is defined, no manual crap
  users.mutableUsers = false;
}
