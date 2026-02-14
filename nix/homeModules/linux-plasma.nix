{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = {
    home = {
      # Session variables are set by the Plasma session itself
      # Desktop-specific session variables (XDG_CURRENT_DESKTOP, etc.) would conflict with other WMs

      packages = with pkgs; [
        # Plasma-specific packages
        kdePackages.plasma-workspace
        kdePackages.plasma-desktop
        kdePackages.kwin

        # Plasma utilities
        kdePackages.spectacle # Screenshots

        # KDE portal for Wayland
        kdePackages.xdg-desktop-portal-kde
      ];
    };

    # kitty configuration moved to linux-wayland.nix to avoid duplication

    # Note: For full Plasma setup, you'll also need to enable it at the system level
    # in your NixOS configuration with:
    # services.displayManager.sddm.enable = true;
    # services.displayManager.sddm.wayland.enable = true;
    # services.desktopManager.plasma6.enable = true;
  };
}
