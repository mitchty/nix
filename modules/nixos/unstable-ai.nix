{ specialArgs,
  inputs,
  ... }: {
    imports = let
      inherit (specialArgs) system;
      inherit (inputs.latest.legacyPackages.${system}) open-webui ollama;
    in [
      # Disable 24.05 ollama nixos service and use unstable ollama package
      {
        # disabledModules = [ "services/misc/ollama.nix" ];
        # nixpkgs.overlays = [ (self: super: { inherit ollama; }) ];
      }
#      (inputs.latest + /nixos/modules/services/misc/ollama.nix)
 #     (inputs.latest + /nixos/modules/services/misc/open-webui.nix)
    ];
  }
