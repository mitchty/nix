{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    unstable.url = "github:NixOS/nixpkgs/master";
    # Follow same nixpkgs as the nixos release for the rest
    # Unless/until we find out that doesn't work
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, emacs-overlay, deploy-rs, ... }:
    let
      # for now we'll just do one nixos-system
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          emacs-overlay.overlay
        ];
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      homeConfigurations = {
        mitch = inputs.home-manager.lib.homeManagerConfiguration {
          inherit system;
          homeDirectory = "/home/mitch";
          username = "mitch";
          configuration = { config, pkgs, ... }: {
            imports = [
              ./users/mitch/home.nix
            ];
          };
        };
      };
      nixosConfigurations = {
        nexus = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nexus/configuration.nix
          ];
        };
      };

      # For home-manager to work
      mitch = self.homeConfigurations.mitch.activationPackage;
      defaultpackage.x86_64-linux = self.mitch;

      deploy = {
        sshUser = "mitch";
        user = "root";
        autoRollback = false;
        magicRollback = false;

        nodes = {
          "nexus" = {
            hostname = "10.10.10.200";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nexus";
            };
          };
        };
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
