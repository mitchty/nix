{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.powerjoular;
in
{
  options.services.mitchty.powerjoular = {
    enable = mkEnableOption "powerjoular daemon";

    outputDir = mkOption {
      type = types.str;
      default = "/run/powerjoular";
      description = "Directory where powerjoular will write CSV data";
    };

    interval = mkOption {
      type = types.int;
      default = 1000;
      description = "Sampling interval in milliseconds";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powerjoular ];

    systemd.services.powerjoular = {
      description = "PowerJoular power monitoring daemon";
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        linuxPackages.nvidia_x11 # nvidia-smi for NVIDIA GPUs
        rocmPackages.rocm-smi # rocm-smi for AMD GPUs
      ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.outputDir}";
        ExecStart = "${pkgs.powerjoular}/bin/powerjoular -o ${cfg.outputDir}/powerjoular.csv -t ${toString cfg.interval}";
        Restart = "always";
        RestartSec = "5s";
        RuntimeDirectory = "powerjoular";
        RuntimeDirectoryMode = "0755";
      };
    };
  };
}
