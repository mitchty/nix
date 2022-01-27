{ pkgs, lib, ... }: {
  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  environment.systemPackages = with pkgs; [
    linuxPackages.cpupower
    linuxPackages.perf
    mosh
    s-tui
    strace
    thin-provisioning-tools
    tmux
    vim
  ];
}
