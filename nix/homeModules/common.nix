{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = with inputs.self.homeModules; [
    git
    sh
  ];

  programs.direnv = {
    enable = true;
    stdlib = lib.readFile ../../static/home/direnvrc;
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".canary".text = "ok";
  # TODO: This should be a gui type homeModule
  home.packages = with pkgs; [
    paid-fonts
  ];

  # This should go in a gooey module
  fonts.fontconfig.enable = true;

  # TODO: need to brain how to tack this into my direnvrc setup
  #   # xdg.configFile."direnv/direnvrc".text =
  #   #   "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

  #   programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
  #     man.generateCaches = true;
  #   };
}
