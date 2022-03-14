{ inputs, pkgs, lib, ... }: {
  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  environment.systemPackages = with pkgs; [
    btop
    dropwatch
    dstat
    inputs.unstable.legacyPackages.${pkgs.system}.polkit
    iotop
    jq
    linuxPackages.cpupower
    linuxPackages.perf
    mosh
    powertop
    s-tui
    strace
    thin-provisioning-tools
    tmux
    vim
  ];
}
