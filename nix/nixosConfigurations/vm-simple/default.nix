{ inputs, ... }:
{
  system = "x86_64-linux";

  modules = [
    # TODO: this no worky at fixing the home-manager-USER.service thing, future
    # mitch figure it out and look at source like a professional.
    #    inputs.home-manager.nixosModules.home-manager
    ./configuration.nix
    {
      system.stateVersion = "24.11";
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "vm-simple";
    }
  ];
}
# TODO: Maybe yeet ideas from this comment
#https://github.com/nix-community/disko/issues/613#issuecomment-2079307891

# Build a function that can take a string and build a nixosConfiguration that embeds the target nixosConfiguration and installs it in the iso like autoinstall?

# Still need to brain how the heck to get around this infinite recursion error in disko.
