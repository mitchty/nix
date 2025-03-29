{ inputs, ... }:
{
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.disko.nixosModules.default
    ./disko.nix
    ./configuration.nix
  ];
}
