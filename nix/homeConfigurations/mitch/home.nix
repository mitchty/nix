{ inputs
, ...
}:
{
  # imports = [
  #   ./packages.nix
  #   ./vscode.nix
  #   ./niri.nix
  # ];

  home = {
    stateVersion = "24.11";
    username = "mitch";
    homeDirectory = "/home/mitch";
    # shellAliases = {
    #   ls = "eza";

  };
}
