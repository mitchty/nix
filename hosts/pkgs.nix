{ inputs, lib, pkgs, ... }: {
  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  programs.bash.enableCompletion = true;
  programs.zsh.enableCompletion = true;

  #  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    cifs-utils
    conntrack-tools
    dmidecode
    dropwatch
    dstat
    iotop
    jq
    linux-firmware
    linuxPackages.cpupower
    linuxPackages.perf
    masscan
    mosh
    nfs-utils
    nftables
    nmap
    pciutils
    pkgs.unstable.nvtopPackages.full
    polkit
    powertop
    psmisc
    s-tui
    smem
    sshpass
    strace
    tcpdump
    thin-provisioning-tools
    tmux
    vim
  ];
}
