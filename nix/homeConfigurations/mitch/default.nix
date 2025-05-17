{ inputs, ... }:
{
  system = "x86_64-linux";
  #  modules = [ inputs.self.homeModules.common ];
  modules = [
    {
      home = {
        stateVersion = "24.11";
        username = "mitch";
        homeDirectory = "/home/mitch";
        # shellAliases = {
        #   ls = "eza";
      };
    }
  ];
}
