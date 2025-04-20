{ inputs, ... }:
{
  system = "x86_64-linux";

  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.self.nixosModules.kernel
    inputs.self.nixosModules.boot
    inputs.self.nixosModules.ssh
    inputs.self.nixosModules.sudo
    inputs.self.nixosModules.nix-common
    inputs.self.nixosModules.user-root
    inputs.self.nixosModules.user-mitch

    # TODO: this no worky at fixing the home-manager-USER.service thing, future
    # mitch figure it out and look at source like a professional.
    #    ./configuration.nix
    (import ./disko.nix { })
    {
      system.stateVersion = "24.11";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-simple";
      #      home-manager.users.mitch.home.stateVersion = "24.11";
    }
  ];
}
# TODO: Maybe yeet ideas from this comment
#https://github.com/nix-community/disko/issues/613#issuecomment-2079307891

# Build a function that can take a string and build a nixosConfiguration that embeds the target nixosConfiguration and installs it in the iso like autoinstall?

# Still need to brain how the heck to get around this infinite recursion error in disko.
