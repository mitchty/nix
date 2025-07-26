{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  name = "ollama";
  cfg = config.services.mitchty.${name};
  varRun = "/var/run/${name}";
  varLib = "/var/lib/${name}";
  varLog = "/var/log";
  stdout = "${varLog}/${name}.stdout.log";
  stderr = "${varLog}/${name}.stderr.log";
in
{
  options.services.mitchty.${name} = {
    enable = mkEnableOption (lib.mdDoc "${name} daemon");
    package = mkOption {
      type = types.package;
      default = pkgs.unstable.${name};
      defaultText = literalExpression "pkgs.unstable.${name}";
      description = lib.mdDoc "The package to use for ${name}";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.daemons.${name} = {
      script = ''
        ${pkgs.coreutils}/bin/install -dm755 ${varRun} ${varLib}
        . ${../../src/lib.sh}
        rotatelog 3 ${stdout} ${stderr}
        ${cfg.package}/bin/${name} serve
      '';
      serviceConfig = {
        EnvironmentVariables.HOME = varLib;
        KeepAlive = true;
        RunAtLoad = true;
        LowPriorityIO = true;
        ProcessType = "Adaptive";
        StandardOutPath = stdout;
        StandardErrorPath = stderr;
      };
    };
  };
}
