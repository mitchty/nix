{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # TODO: Go through the entire nix-darwin docs and find more crap to toggle
  # like a dumass. This isn't critical probably shouldn't change a ton anyway.
  # https://nix-darwin.github.io/nix-darwin/manual/index.html
  # also look at https://macos-defaults.com
  system = {
    defaults = {
      CustomUserPreferences = {
        # For the force paste script
        "com.apple.scriptmenu" = {
          ScriptMenuEnabled = true;
          ShowLibraryScripts = false;
        };
        # Mostly here to make the menu bar a bit more useful
        "com.apple.systemuiserver"."NSStatusItem Visible Siri" = false;
        # Don't pollute network or usb fs's with .DS_Store turds
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
    };
  };
}
