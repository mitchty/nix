{ inputs, pkgs, ... }: {
  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  environment.systemPackages = with pkgs; [
    btop
    conntrack-tools
    cifs-utils
    dmidecode
    dropwatch
    dstat
    inputs.unstable.legacyPackages.${pkgs.system}.polkit
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
