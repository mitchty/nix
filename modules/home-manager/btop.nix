{ inputs, pkgs, ... }: {
  home.packages = with inputs.latest.legacyPackages.${pkgs.system}; [
    btop
  ];

  # Basically btop defaults but we ignore /boot:/boot* filesystems
  home.file.".config/btop/btop.conf".source = ../../static/btop/btop.conf;
}
