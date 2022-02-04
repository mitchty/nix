{ pkgs, lib, ... }: {
  imports = [
    ./bootstrap.nix
    ../hosts/nix-basic.nix
  ];
  programs.nix-index.enable = true;

  # Minimal setup of what we want installed outside of home-manager
  environment.systemPackages = with pkgs; [
    vim
    mosh
    git
    tmux
    jq
  ];
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
}
