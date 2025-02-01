{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.wiffy;
in
{
  options.services.role.wiffy = {
    enable = mkEnableOption "Setup wifi networkmanager connection file(s)";
  };
  config = mkIf cfg.enable rec {
    # Setup networkmanager connection files for wiffy connections
    environment.etc."NetworkManager/system-connections/Lost Fox Guest.nmconnection" = {
      source = config.age.secrets."wifi/lostfox".path;
      mode = "0400";
    };
    environment.etc."NetworkManager/system-connections/newerhotness.nmconnection" = {
      source = config.age.secrets."wifi/newerhotness".path;
      mode = "0400";
    };
    environment.etc."NetworkManager/system-connections/Gambit Guest.nmconnection" = {
      source = config.age.secrets."wifi/gambit".path;
      mode = "0400";
    };
  };
}
