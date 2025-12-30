{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.mitchty.ollama;
in
{
  # Use the versions from unstable and not the YY.MM channel
  disabledModules = [
    "services/misc/ollama.nix"
  ];

  imports = [
    (inputs.nixpkgs-ai + /nixos/modules/services/misc/ollama.nix)
  ];

  options.services.mitchty.ollama = {
    enable = mkEnableOption "Setup as an ollama server";
    cname = mkOption {
      type = types.str;
      default = "ollama.home.arpa";
      description = "dns domain to use for the ollama service";
    };
    ip = mkOption {
      type = types.str;
      default = "10.10.10.220";
      description = "ollama ip address";
    };
    pkg = mkOption {
      type = types.package;
      default = pkgs.ai-nvidia.ollama;
      description = "Default package derivation to use for ollama";
    };
    iface = mkOption {
      type = types.str;
      default = "br0";
      description = "interface to add vip to for ip";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      interfaces = {
        "${cfg.iface}" = {
          ipv4.addresses = [
            {
              address = cfg.ip;
              prefixLength = 24;
            }
          ];
        };
      };
      firewall = {
        interfaces = {
          "${cfg.iface}" = {
            allowedTCPPorts = [
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
      host = cfg.ip;
      package = cfg.pkg;
      # acceleration = "cuda";
      # Just set the rocm/cuda options and pacakge not here.
      # https://search.nixos.org/options?channel=25.05&show=services.ollama.acceleration&query=services.ollama
      # nixpkgs.config.rocmSupport is enabled, uses "rocm"
      # nixpkgs.config.cudaSupport is enabled, uses "cuda"
      environmentVariables = {
        # TODO what is the var to control how long ollama takes to purge a model? Future mitch fix it.
        OLLAMA_MAX_LOADED_MODELS = "2";
        OLLAMA_NUM_PARALLEL = "2";
      };
    };
  };
}
