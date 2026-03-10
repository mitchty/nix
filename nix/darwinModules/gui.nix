{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    maccy
    stats
    tradingview-mac
  ];

  system = {
    defaults = {
      CustomUserPreferences = {
        "com.apple.controlcenter" = {
          WiFi = 8; # 8=hide, 18=show, 24=controlcenteronly
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
          Disk_barChart_position = 2;
          Disk_disk = "Macintosh HD";
          Disk_label_position = 1;
          Disk_memory_position = 6;
          Disk_mini_position = 4;
          Disk_networkChart_position = 3;
          Disk_pieChart_position = 5;
          Disk_processes = 10;
          Disk_speed_iconColor = "transparent";
          Disk_speed_position = 0;
          Disk_state = 0;
          Disk_text_position = 7;
          Disk_updateInterval = 30;
          Disk_widget = "speed";
          GPU_barChart_position = 3;
          GPU_gpu = "automatic";
          GPU_label_position = 1;
          GPU_lineChart_position = 0;
          GPU_line_chart_box = 0;
          GPU_line_chart_frame = 0;
          GPU_line_chart_historyCount = 30;
          GPU_mini_position = 2;
          GPU_state = 1;
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
          Sensors_widget = "sensors";
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
}
