{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.ai;
in
{
  # Use the versions from unstable and not the YY.MM channel
  disabledModules = [
    "services/misc/ollama.nix"
    "services/misc/open-webui.nix"
  ];

  imports = [
    (inputs.nixpkgs-unstable + /nixos/modules/services/misc/open-webui.nix)
    (inputs.nixpkgs-unstable + /nixos/modules/services/misc/ollama.nix)
  ];

  options.services.mitchty.ai = {
    enable = mkEnableOption "Setup as an ai llm thingy";
    ollamaCname = mkOption {
      type = types.str;
      default = "slow-ollama.home.arpa";
      description = "Internal dns domain to use for the ollama cname";
    };
    ollamaIp = mkOption {
      type = types.str;
      default = "10.10.10.222";
      description = "ollama ip address";
    };
    owuiCname = mkOption {
      type = types.str;
      default = "slow-open-webui.home.arpa";
      description = "Internal dns domain to use for the open webui cname";
    };
    owuiIp = mkOption {
      type = types.str;
      default = "10.10.10.223";
      description = "open webui ip address";
    };
    iface = mkOption {
      type = types.str;
      default = "enp88s0";
      description = "interface to add vip to";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      interfaces = {
        "${cfg.iface}" = {
          ipv4.addresses = [
            {
              address = cfg.owuiIp;
              prefixLength = 32;
            }
            {
              address = cfg.ollamaIp;
              prefixLength = 32;
            }
          ];
        };
      };
      firewall = {
        interfaces = {
          "${cfg.iface}" = {
            allowedTCPPorts = [
              8080
              11434
            ];
          };
        };
      };
    };

    environment = {
      systemPackages = [
        pkgs.unstable.cudatoolkit
        pkgs.unstable.autoAddDriverRunpath
        pkgs.unstable.autoFixElfFiles
      ];
    };

    hardware = {
      graphics.enable = true;

      nvidia = {
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
        open = false;
        nvidiaSettings = true;
        #        package = config.boot.kernelPackages.nvidiaPackages.stable;
        #        package = pkgs.linuxKernel.packages.linux_6_15.nvidia_x11;
      };
    };

    # boot = {
    #   blacklistedKernelModules = [
    #     "nouveau"
    #     "nvidia"
    #     "nvidia_drm"
    #     "nvidia_modeset"
    #   ];
    #   extraModulePackages = [
    #     pkgs.linuxPackages.nvidia_x11
    #   ];
    # };

    services.ollama = {
      enable = true;
      host = cfg.ollamaIp;
      acceleration = "cuda";
      package = pkgs.unstable.ollama-cuda;
      environmentVariables = {
        # TODO what is the var to control how long ollama takes to purge a model? Future mitch fix it.
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "1";
      };
    };

    services.open-webui = {
      enable = true;
      host = cfg.owuiIp;
      port = 8080;
      environment = {
        SCARF_NO_ANALYTICS = "True";
        DO_NOT_TRACK = "True";
        ANONYMIZED_TELEMETRY = "False";
        OLLAMA_API_BASE_URL = "http://${cfg.ollamaCname}:11434";
        WEBUI_AUTH = "False";
        WEBUI_URL = "http://${cfg.owuiCname}";
        GLOBAL_LOG_LEVEL = "DEBUG";
      };
      package = pkgs.unstable.open-webui;
    };
  };
}
