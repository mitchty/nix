{
  description = "initial flake configuration setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    unstable.url = "nixpkgs/master";
    # Follow same nixpkgs as the system for home-manager
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    # inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = { self, nixpkgs, home-manager, emacs-overlay, deploy-rs, ... }@inputs:
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
      homeManagerConfigurations = {
        mitch = home-manager.lib.homeManagerConfiguration {
          inherit system pkgs;
          username = "mitch";
          homeDirectory = "/home/mitch";
          configuration = {
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
