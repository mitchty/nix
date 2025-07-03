{ inputs, ... }:
{
  system = "x86_64-linux";
  #  modules = [ inputs.self.homeModules.common ];
  modules = [
    {
      home = {
        stateVersion = "25.05";
        username = "mitch";
        homeDirectory = "/home/mitch";
        # shellAliases = {
        #   ls = "eza";
      };
    }
  ];
}
