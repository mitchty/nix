{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  home = {
    packages = with pkgs; [
      htop
      du-dust
      bcc
      tcpdump
      hwatch
      dig
      fio
      pv
      stress
    ];
  };

  home = {
    file = {
      ".config/btop/btop.conf".source = ../../static/btop/btop.conf;
      ".canary".text = "ok";
    };
  };

  programs.direnv = {
    enable = true;
    stdlib = lib.readFile ../../static/home/direnvrc;
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # TODO: need to brain how to tack this into my direnvrc setup
  #   # xdg.configFile."direnv/direnvrc".text =
  #   #   "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

  #   programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
  #     man.generateCaches = true;
  #   };
}
