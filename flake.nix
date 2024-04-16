{
  description = "mitchty nix flake monorepo o doom shenanigans refactor effort";

  outputs = { flakelight, ... }@inputs: flakelight ./. rec {
    inherit inputs;
    devShell.packages = pkgs: [ pkgs.hello pkgs.coreutils ];
    legacyPackages = pkgs: pkgs;
    # TODO: grouping of overlays to reduce pointless line count
    withOverlays = [
      inputs.emacs-overlay.overlays.default
      inputs.rust.overlays.default
      inputs.self.overlays.altshfmt
      inputs.self.overlays.asm-lsp
      inputs.self.overlays.emacs
      inputs.self.overlays.fonts
      inputs.self.overlays.hatools
      inputs.self.overlays.hponcfg
      inputs.self.overlays.oldscripts
      inputs.self.overlays.transcrypt
    ];
  };

  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Overlays
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Below here are the things that aren't updated as often.
    # Not overriding inputs.nixpkgs due to
    # https://github.com/nix-community/disko/blob/master/flake.nix#L4
    disko.url = "github:nix-community/disko";

    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };
}
