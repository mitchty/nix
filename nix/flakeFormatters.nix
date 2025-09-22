{ inputs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixpkgs-fmt.enable = true;
    shell.enable = true;
    taplo.enable = true;
  };
}
