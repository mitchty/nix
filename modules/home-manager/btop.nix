{ pkgs, ... }: {
  home.packages = [ pkgs.unstable.btop ];

  # Basically btop defaults but we ignore /boot:/boot* filesystems
  home.file.".config/btop/btop.conf".source = ../../static/btop/btop.conf;
}
