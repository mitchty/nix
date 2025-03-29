{
  description = "my nix flakelight configuration rewrite... attempt (partier deux)";

  outputs = { flakelight, ... }@inputs:
    flakelight ./. {
      imports = [ inputs.flakelight-elisp.flakelightModules.default ];
      inherit inputs;
      withOverlays = [
        (final: prev: {
          # Exposes each input as pkgs.name in the normal package set
          #
          # Not quite an "overlay" but a way to abuse different package inputs
          # or use all of em if I want in my own derivations.
          unstable = import inputs.unstable {
            system = prev.system;
            config = {
              allowUnfree = true;
            };
          };
          open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
          nix-update = inputs.nix-update.packages.${prev.system}.nix-update;
        })
        inputs.nixgl.overlays.default
        inputs.emacs-overlay.overlay
        inputs.deploy-rs.overlay
        inputs.agenix.overlays.default
        inputs.fenix.overlays.default
        inputs.nur.overlays.default
        inputs.self.overlays.overrides
        inputs.self.overlays.emacs
      ];
      checks.statix = pkgs: "${pkgs.statix}/bin/statix check";
      legacyPackages = pkgs: pkgs;
      formatter = pkgs: pkgs.nixfmt-rfc-style;
    };

  nixConfig.commit-lockfile-summary = "flake: Update inputs";

  # Just inputs after here. TODO: some of these might be derivations in disguise
  # future mitch figure it out.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flakelight-elisp = {
      url = "github:accelbread/flakelight-elisp";
      inputs.flakelight.follows = "flakelight";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-update = {
      url = "github:MiC92/nix-update";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    dnsblacklist = {
      url = "github:hagezi/dns-blocklists";
      flake = false;
    };
    agenix.url = "github:ryantm/agenix";
    open-webui-cli.url = "github:mitchty/open-webui-cli";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
