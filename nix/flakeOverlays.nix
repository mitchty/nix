{
  inputs,
  lib,
  ...
}:
[
  (final: prev: rec {
    # Exposes each input as pkgs.name in the normal package set
    #
    # Not quite an "overlay" but a way to abuse different package inputs
    # or use all of em if I want in derivations here.
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config = {
        allowUnfree = true;
      }
      // lib.optionalAttrs (final.stdenv.isLinux) {
        allowUnfree = true;
        allowCuda = true;
        cudaSupport = true;
        rocmSupport = true;
      };
      overlays = [
        inputs.self.overlays.overrides
      ];
    };

    # For when/if I need to distinguish the ai unstable tracking from reg
    # unstable nixpkgs. Also constrains cuda support for stuff. Maybe I setup
    # two ai-nv and ai-amd for the wm2? Future mitch problem...
    ai = import inputs.nixpkgs-ai {
      inherit (final) system;
      config = {
        allowUnfree = true;
      }
      // lib.optionalAttrs (final.stdenv.isLinux) {
        allowUnfree = true;
        allowCuda = true;
        cudaSupport = true;
      };
      overlays = [
        inputs.self.overlays.overrides
      ];
    };

    # TODO: Should I even keep this here? Also nix-hardware needs to get
    # in here at some point.
    cf-dns-update = inputs.cf-dns-update.packages.${prev.system}.default;
    kairos = inputs.kairos.packages.${prev.system}.default;
    open-webui-cli = inputs.open-webui-cli.packages.${prev.system}.release;
    inherit (inputs.nix-update.packages.${prev.system}) nix-update;
    inherit (inputs.nixos-generators.packages.${prev.system}) nixos-generate;
    inherit (inputs.home-manager.packages.${prev.system}) home-manager;
    inherit (inputs.omnix.packages.${prev.system}) omnix-cli;

    # For nixpkgs-unstable open-webui to build on 25.05
    # pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    #   (pyfinal: pyprev: {
    #     ddgs = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.pkgs.python312Packages.ddgs;
    #   })
    # ];
  })
  inputs.eca.overlays.default
  inputs.emacs-overlay.overlay
  inputs.deploy-rs.overlays.default
  inputs.agenix.overlays.default
  #  inputs.ragenix.overlays.default
  inputs.fenix.overlays.default
  inputs.nur.overlays.default
]
++ (with inputs.self.overlays; [
  overrides
  yt-dlp
  emacs
])
