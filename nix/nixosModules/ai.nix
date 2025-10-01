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
    (inputs.nixpkgs-ai + /nixos/modules/services/misc/open-webui.nix)
    (inputs.nixpkgs-ai + /nixos/modules/services/misc/ollama.nix)
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
    ollamaPackage = mkOption {
      type = types.package;
      default = pkgs.ai-nvidia.ollama;
      description = "Default package derivation to use for ollama";
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
    owuiPackage = mkOption {
      type = types.package;
      default = pkgs.ai-nvidia.open-webui;
      description = "Default package derivation to use for open-webui";
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
              prefixLength = 24;
            }
            {
              address = cfg.ollamaIp;
              prefixLength = 24;
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
        pkgs.ai-nvidia.cudatoolkit
        pkgs.ai-nvidia.autoAddDriverRunpath
        pkgs.ai-nvidia.autoFixElfFiles
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
      package = cfg.ollamaPackage;
      acceleration = "cuda";
      # Just set the rocm/cuda options and pacakge not here.
      # https://search.nixos.org/options?channel=25.05&show=services.ollama.acceleration&query=services.ollama
      # nixpkgs.config.rocmSupport is enabled, uses "rocm"
      # nixpkgs.config.cudaSupport is enabled, uses "cuda"
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
      package = cfg.owuiPackage;
    };
  };
}
