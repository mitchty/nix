{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.mitchty;
  fake = lib.fakeSha256;

  # Scripts I wrote that are macos only.
  close = (pkgs.writeScriptBin "close" (builtins.readFile ../../static/src/close)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  nopb = (pkgs.writeScriptBin "nopb" (builtins.readFile ../../static/src/nopb)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  gohome = (pkgs.writeScriptBin "gohome" (builtins.readFile ../../static/src/gohome)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  reopen = (pkgs.writeScriptBin "reopen" (builtins.readFile ../../static/src/reopen)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
in
{
  options = {
    services.mitchty = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          My custom crap for macos.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.multitail
      inputs.mitchty.packages.${pkgs.system}.ferdium
      inputs.mitchty.packages.${pkgs.system}.freetube
      inputs.mitchty.packages.${pkgs.system}.hidden
      inputs.mitchty.packages.${pkgs.system}.maccy
      inputs.mitchty.packages.${pkgs.system}.nheko
      inputs.mitchty.packages.${pkgs.system}.notunes
      inputs.mitchty.packages.${pkgs.system}.keepingyouawake
      #      inputs.mitchty.packages.${pkgs.system}.obs-studio
      inputs.mitchty.packages.${pkgs.system}.stats
      inputs.mitchty.packages.${pkgs.system}.swiftbar
      inputs.mitchty.packages.${pkgs.system}.vlc
      inputs.mitchty.packages.${pkgs.system}.wireshark
      close
      gohome
      nopb
      reopen
    ];

    system = {
      defaults = {
        CustomUserPreferences = {
          "info.marcel-dierkes.KeepingYouAwake" = {
            "info.marcel-dierkes.KeepingYouAwake.AllowDisplaySleep" = true;
          };
          "org.p0deje.Maccy" = {
            SUSendProfileInfo = false;
            pasteByDefault = false;
            SUEnableAutomaticChecks = false;
            clearSystemClipboard = true;
          };
          "eu.exelban.Stats" = {
            "sensor_Average System Total" = false;
            "sensor_Fastest Fan" = true;
            "sensor_Hottest CPU" = false;
            "sensor_Total System Consumption" = true;
            Battery_barChart_position = 4;
            Battery_bar_chart_box = true;
            Battery_bar_chart_color = "utilization";
            Battery_bar_chart_label = false;
            Battery_batteryDetails_position = 0;
            Battery_battery_details_mode = "percentageAndTime";
            Battery_battery_position = 3;
            Battery_label_position = 2;
            Battery_lowLevelNotification = 0.1;
            Battery_mini_position = 1;
            Battery_processes = 10;
            Battery_timeFormat = "long";
            Battery_updateInterval = 10;
            Battery_widget = "battery_details";
            CPU_barChart_position = 4;
            CPU_label_position = 1;
            CPU_lineChart_position = 0;
            CPU_line_chart_box = false;
            CPU_line_chart_color = "utilization";
            CPU_line_chart_frame = false;
            CPU_line_chart_historyCount = 120;
            CPU_mini_color = "utilization";
            CPU_mini_position = 2;
            CPU_pieChart_position = 3;
            CPU_processes = 10;
            CPU_tachometer_position = 5;
            CPU_updateInterval = 10;
            CPU_updateTopInterval = 10;
            CPU_widget = "line_chart";
            Disk_state = false;
            Disk_updateInterval = 30;
            GPU_barChart_position = 3;
            GPU_label_position = 1;
            GPU_lineChart_position = 0;
            GPU_line_chart_box = false;
            GPU_line_chart_frame = false;
            GPU_line_chart_historyCount = 30;
            GPU_mini_position = 2;
            GPU_state = false;
            GPU_tachometer_position = 4;
            GPU_updateInterval = 10;
            GPU_widget = "line_chart";
            LaunchAtLoginNext = false; # Causing issues for some reason with duplicate Stats instances now, watever
            Network_label_position = 1;
            Network_networkChart_position = 0;
            Network_network_chart_box = false;
            Network_network_chart_commonScale = true;
            Network_network_chart_downloadColor = "secondBlue";
            Network_network_chart_frame = false;
            Network_network_chart_historyCount = 120;
            Network_network_chart_label = false;
            Network_network_chart_scale = "square";
            Network_network_chart_uploadColor = "secondRed";
            Network_processes = 10;
            Network_publicIPRefreshInterval = "hour";
            Network_reader = "interface";
            Network_speed_position = 2;
            Network_usageReset = "Once per day";
            Network_widget = "network_chart";
            RAM_barChart_position = 2;
            RAM_label_position = 1;
            RAM_lineChart_position = 0;
            RAM_line_chart_box = false;
            RAM_line_chart_color = "pressure";
            RAM_line_chart_frame = false;
            RAM_line_chart_historyCount = 120;
            RAM_memory_position = 5;
            RAM_mini_position = 3;
            RAM_pieChart_position = 4;
            RAM_processes = 10;
            RAM_tachometer_position = 6;
            RAM_updateInterval = 10;
            RAM_updateTopInterval = 10;
            RAM_widget = "line_chart";
            Sensors_barChart_position = 1;
            Sensors_bar_chart_box = false;
            Sensors_bar_chart_color = "utilization";
            Sensors_fanValue = "percentage";
            Sensors_label_position = 2;
            Sensors_oneView = true;
            Sensors_sensors_mode = "twoRows";
            Sensors_sensors_position = 0;
            Sensors_state = true;
            Sensors_updateInterval = 30;
            Sensors_widget = "sensors,bar_chart";
            runAtLoginInitialized = true;
            sensor_ID0R = true;
            sensor_PDTR = true;
            sensor_PSTR = false;
            sensor_VCAC = false;
            sensor_VD0R = false;
            telemetry = false;
          };
        };
      };
    };

    # Following should allow us to avoid a logout/login cycle to disable
    # shortcuts that conflict withe emacs.
    # https://apple.stackexchange.com/questions/13598/updating-modifier-key-mappings-through-defaults-command-tool
    # https://apple.stackexchange.com/questions/201816/how-do-i-change-mission-control-shortcuts-from-the-command-line
    #
    # https://superuser.com/questions/1211108/remove-osx-spotlight-keyboard-shortcut-from-command-line
    system.activationScripts.postUserActivation.text = ''
      printf "modules/darwin/mitchty.nix: login related changes (may require a login/logout cycle if it doesn't work)\n" >&2

      # Disables command+shift+5 which conflicts with emacs meta+%
      $DRY_RUN_CMD /usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist \
        -c "Delete :AppleSymbolicHotKeys:184" \
        -c "Add :AppleSymbolicHotKeys:184:enabled bool false" \
        -c "Add :AppleSymbolicHotKeys:184:value:parameters array" \
        -c "Add :AppleSymbolicHotKeys:184:value:parameters: integer 53" \
        -c "Add :AppleSymbolicHotKeys:184:value:parameters: integer 53" \
        -c "Add :AppleSymbolicHotKeys:184:value:parameters: integer 1179648" \
        -c "Add :AppleSymbolicHotKeys:184:type string standard"

      # TODO: off for now
      # Disables command+space shortcut
      $DRY_RUN_CMD /usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist \
        -c "Delete :AppleSymbolicHotKeys:64" \
        -c "Add :AppleSymbolicHotKeys:64:enabled bool true" \
        -c "Add :AppleSymbolicHotKeys:64:value:parameters array" \
        -c "Add :AppleSymbolicHotKeys:64:value:parameters: integer 32" \
        -c "Add :AppleSymbolicHotKeys:64:value:parameters: integer 49" \
        -c "Add :AppleSymbolicHotKeys:64:value:parameters: integer 1048576" \
        -c "Add :AppleSymbolicHotKeys:64:type string standard"

      $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
      $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
