{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # TODO: Go through the entire nix-darwin docs and find crap to toggle like a dumass.
  system = {
    defaults = {
      CustomUserPreferences = {
        # For the force paste script
        "com.apple.scriptmenu" = {
          ScriptMenuEnabled = true;
          ShowLibraryScripts = false;
        };
        # Mostly here to make the menu bar a bit more useful
        "com.apple.systemuiserver" = {
          "NSStatusItem Visible Siri" = false;
          menuExtras = [
            "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
            "/System/Library/CoreServices/Menu Extras/Clock.menu"
          ];
        };
        # Don't pollute network or usb fs's with .DS_Store turds
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
    };
  };
}
