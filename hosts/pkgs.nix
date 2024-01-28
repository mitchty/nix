{ inputs, lib, pkgs, ... }: {
  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  programs.bash.enableCompletion = true;
  programs.zsh.enableCompletion = true;

  environment.systemPackages = with pkgs; [
    btop
    conntrack-tools
    dmidecode
    dropwatch
    dstat
    inputs.latest.legacyPackages.${pkgs.system}.polkit
    iotop
    jq
    linux-firmware
    linuxPackages.cpupower
    linuxPackages.perf
    masscan
    mosh
    nftables
    nfs-utils
    nmap
    pciutils
    powertop
    psmisc
    smem
    s-tui
    strace
    tcpdump
    thin-provisioning-tools
    tmux
    vim
  ];
}
