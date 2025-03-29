{ inputs, ... }:
{
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    ./configuration.nix
  ];
}
