{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.wiffy;
in
{
  options.services.mitchty.wiffy = {
    enable = mkEnableOption "Setup wifi networkmanager connection file(s)";
  };
  config = mkIf cfg.enable {
    # For the intel iwl driver to load otherwise I get this crap
    # [    4.761598] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-89.ucode failed with error -2
    # [    4.761624] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-88.ucode failed with error -2
    # [    4.761652] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-87.ucode failed with error -2
    # [    4.761676] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-86.ucode failed with error -2
    # [    4.761703] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-85.ucode failed with error -2
    # [    4.761726] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-84.ucode failed with error -2
    # [    4.761752] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-83.ucode failed with error -2
    # [    4.761779] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-82.ucode failed with error -2
    # [    4.761808] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-81.ucode failed with error -2
    # [    4.761837] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-80.ucode failed with error -2
    # [    4.761865] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-79.ucode failed with error -2
    # [    4.761893] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-78.ucode failed with error -2
    # [    4.761922] iwlwifi 0000:02:00.0: Direct firmware load for iwlwifi-ty-a0-gf-a0-77.ucode failed with error -2
    hardware.enableRedistributableFirmware = true;
    age.secrets = {
      "secrets/wifi/lostfox" = {
        file = ../../secrets/wifi/lostfox.age;
        owner = "root";
      };
      "secrets/wifi/newerhotness" = {
        file = ../../secrets/wifi/newerhotness.age;
        owner = "root";
      };
      "secrets/wifi/gambit" = {
        file = ../../secrets/wifi/gambit.age;
        owner = "root";
      };
      # later...
      # "secrets/wifi/pp" = {
      #   file = ../../secrets/wifi/pp.age;
      #   owner = "root";
      # };
    };

    # Setup networkmanager connection files for wiffy connections
    environment.etc = {
      "NetworkManager/system-connections/Lost Fox Guest.nmconnection" = {
        source = config.age.secrets."secrets/wifi/lostfox".path;
        mode = "0400";
      };
      "NetworkManager/system-connections/newerhotness.nmconnection" = {
        source = config.age.secrets."secrets/wifi/newerhotness".path;
        mode = "0400";
      };
      "NetworkManager/system-connections/Gambit Guest.nmconnection" = {
        source = config.age.secrets."secrets/wifi/gambit".path;
        mode = "0400";
      };
    };
    # environment.etc."NetworkManager/system-connections/Pinkiepie-2555bed6-7376-4a7a-88a2-901445b2191b.nmconnection" =
    #   {
    #     source = config.age.secrets."secrets/wifi/pp".path;
    #     mode = "0400";
    #   };
  };
}
