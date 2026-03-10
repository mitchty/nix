{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  mylib = import ../lib.nix { inherit lib; };

  # How long a model will remain in memory, karakeep gets the longer ttl as I
  # might bookmark stuff over a bit more time than the rest so it can stay in
  # memory for a bit.
  longTtl = (60 * 30);
  shortTtl = (60 * 10);

  cfg = config.services.mitchty.llama-swap;

  models = builtins.mapAttrs (_: spec: mylib.fetchhf pkgs spec) mylib.llamaModels;

  # llama-swap and llama-cpp-blas are now defined in nix/overlays/
  # and applied to pkgs.unstable via flakeOverlays.nix unstableOverlays

  # TODO: Figure out how to get this beast to build, I need oneMath somehow for compiler support.
  # This is as is tradition a future mitch problem.
  llama-cpp-intel = pkgs.llama-cpp.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      pkgs.cmake
      pkgs.ninja
      pkgs.git
    ];
    buildInputs = (old.buildInputs or [ ]) ++ [
      pkgs.oneDNN
      #        pkgs.oneMath
      pkgs.tbb_2022
      pkgs.mkl
      pkgs.opencl-headers
      pkgs.ocl-icd
      pkgs.curl
    ];
    hardeningDisable = (old.hardeningDisable or [ ]) ++ [
      "zerocallusedregs"
      "pacret"
      #            "shadowstack"
    ];
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      "-DGGML_SYCL=ON"
    ];
    preConfigure = ''
      export NIX_ENFORCE_NO_NATIVE=0
      ${old.preConfigure or ""}
    '';
  });
in
{
  options.services.mitchty.llama-swap = {
    enable = mkEnableOption "Setup as a llama-swap capable system";
    cname = mkOption {
      type = types.str;
      default = "llama.home.arpa";
      description = "Internal dns domain to use for llama-swap usage";
    };
    ip = mkOption {
      type = types.str;
      default = "10.10.10.226";
      description = "llama-swap ip address to bind to";
    };
    pkg = mkOption {
      type = types.package;
      default = pkgs.unstable.llama-swap;
      description = "Default package derivation to use for llama-swap";
    };
    llamaCpppkg = mkOption {
      type = types.package;
      default = pkgs.unstable.llama-cpp;
      description = "Default package derivation to use for llama-swap";
    };
    iface = mkOption {
      type = types.str;
      default = "br0";
      description = "interface to add vip to";
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
              8080
              11343
            ];
          };
        };
      };
    };

    environment = {
      systemPackages = [
        pkgs.llama-cpp
      ];
    };

    services.llama-swap = {
      enable = true;
      package = cfg.pkg;
      port = 11343;
      openFirewall = true;
      settings =
        let
          llama-server = lib.getExe' cfg.llamaCpppkg "llama-server";
        in
        {
          healthCheckTimeout = 1200;
          groups = {
            karakeep = {
              swap = false;
              exclusive = true;
              members = [
                "gemma3"
                "llava"
                # "gpt-oss-20b"
                # "qwen3"
              ];
            };
          };

          logLevel = "debug";

          models = {
            minimax25 = {
              cmd = "${llama-server} --port \${PORT} -m ${models.minimax25} -c 131072";
              ttl = longTtl;
            };
            gemma3 = {
              cmd = "${llama-server} --port \${PORT} -m ${models.gemma3} -c 131072";
              ttl = longTtl;
            };
            llava = {
              cmd = "${llama-server} --port \${PORT} -m ${models.llava}";
              ttl = longTtl;
            };
            gpt-oss-20b = {
              cmd = "${llama-server} --port \${PORT} -m ${models.gpt-oss-20b}";
              ttl = shortTtl;
            };
            qwen3 = {
              cmd = "${llama-server} --port \${PORT} -m ${models.qwen3}";
              ttl = shortTtl;
            };
          };
        };
    };
  };
}
