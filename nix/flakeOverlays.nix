{ inputs, ... }:
[
  inputs.self.overlays.overrides
  inputs.self.overlays.yt-dlp
  inputs.self.overlays.emacs

  (final: prev: rec {
    # Exposes each input as pkgs.name in the normal package set
    #
    # Not quite an "overlay" but a way to abuse different package inputs
    # or use all of em if I want in derivations here.
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev) system;
      config = {
        allowUnfree = true;
        allowCuda = true;
        cudaSupport = true;
        #        rocmSupport = true;
      };
      overlays = [
        inputs.self.overlays.overrides
      ];
    };

    ai = import inputs.nixpkgs-ai {
      inherit (prev) system;
      config = {
        allowUnfree = true;
      };
    };

    # Ok for simplicity I'm going to define all the stuff I normally abuse from unstable here.
    inherit (unstable.pkgs)
      homer
      plex
      sonarr
      radarr
      prowlarr
      sabnzbd
      btop
      ollama-cuda
      open-webui
      ;

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
  inputs.emacs-overlay.overlay
  inputs.self.overlays.emacs
  inputs.deploy-rs.overlays.default
  inputs.agenix.overlays.default
  inputs.fenix.overlays.default
  inputs.nur.overlays.default
]
