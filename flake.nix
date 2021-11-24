{
  description = "initial flake configuration setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    # Keep nixpkgs for home-manager == to the system nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # for now we'll just do one nixos-system
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        nexus = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nexus/configuration.nix
          ];
        };
      };
    };
}
