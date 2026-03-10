{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  mylib = import ../lib.nix { inherit lib; };

  name = "llama-swap";
  cfg = config.services.mitchty.${name};
  varRun = "/var/run/${name}";
  varLib = "/var/lib/${name}";
  varLog = "/var/log";
  stdout = "${varLog}/${name}.stdout.log";
  stderr = "${varLog}/${name}.stderr.log";

  longTtl = (60 * 30);
  shortTtl = (60 * 10);

  models = builtins.mapAttrs (_: spec: mylib.fetchhf pkgs spec) mylib.llamaModels;

  llamaServerBin = lib.getExe' cfg.llamaCpppkg "llama-server";

  configFile = (pkgs.formats.yaml { }).generate "${name}-config.yaml" {
    healthCheckTimeout = 1200;
    logLevel = "debug";
    groups = {
      karakeep = {
        swap = false;
        exclusive = true;
        members = [
          "gemma3"
          "llava"
        ];
      };
    };
    models = {
      flux2 = {
        cmd = "${llamaServerBin} --port \${PORT} -m ${models.flux2}";
        ttl = shortTtl;
      };
      minimax25 = {
        cmd = "${llamaServerBin} --port \${PORT} -m ${models.minimax25} -c 131072";
        ttl = longTtl;
      };
      gemma3 = {
        cmd = "${llamaServerBin} --port \${PORT} -m ${models.gemma3} -c 131072";
        ttl = longTtl;
      };
      llava = {
        cmd = "${llamaServerBin} --port \${PORT} -m ${models.llava}";
        ttl = longTtl;
      };
      qwen3 = {
        cmd = "${llamaServerBin} --port \${PORT} -m ${models.qwen3}";
        ttl = shortTtl;
      };
    };
  };
in
{
  options.services.mitchty.${name} = {
    enable = mkEnableOption (lib.mdDoc "${name} daemon");
    port = mkOption {
      type = types.port;
      default = 11343;
      description = lib.mdDoc "Port for ${name} to listen on";
    };
    pkg = mkOption {
      type = types.package;
      default = pkgs.unstable.llama-swap;
      defaultText = literalExpression "pkgs.unstable.llama-swap";
      description = lib.mdDoc "The package to use for ${name}";
    };
    llamaCpppkg = mkOption {
      type = types.package;
      default = pkgs.unstable.llama-cpp;
      defaultText = literalExpression "pkgs.unstable.llama-cpp";
      description = lib.mdDoc "The llama.cpp package providing llama-server";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.pkg
      cfg.llamaCpppkg
    ];

    launchd.daemons.${name} = {
      script = ''
        ${pkgs.coreutils}/bin/install -dm755 ${varRun} ${varLib}
        . ${../../src/lib.sh}
        rotatelog 3 ${stdout} ${stderr}
        ${cfg.pkg}/bin/${name} --config ${configFile} --listen :${toString cfg.port}
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
