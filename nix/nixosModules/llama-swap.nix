{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  # How long a model will remain in memory, karakeep gets the longer ttl as I
  # might bookmark stuff over a bit more time than the rest so it can stay in
  # memory for a bit.
  longTtl = (60 * 30);
  shortTtl = (60 * 10);

  cfg = config.services.mitchty.llama-swap;
  fetchhf =
    {
      owner,
      repo,
      branch ? "main",
      name,
      hash ? "",
      ...
    }@args:
    pkgs.fetchurl (
      (builtins.removeAttrs args [
        "owner"
        "repo"
        "branch"
      ])
      // {
        url = "https://huggingface.co/${owner}/${repo}/resolve/${branch}/${name}";
        inherit name;
      }
      // lib.optionalAttrs (hash != "") { inherit hash; }
    );

  # Yeet all this crap into a wrapper derivation and let llama-swap use that for its operation
  #
  # Gotta keep all this declarative!

  # Karakeep needs gemma3 and llava for text and image inference/ocr kinda
  # nonsense. We'll let both of these run at once. They'll still timeout when
  # nothings happening but if I'm rerunning stuff on karakeep its nice to not
  # deal with load/unload cycles.

  # https://huggingface.co/MaziyarPanahi/gemma-3-4b-it-GGUF/tree/main
  # gemma3 = fetchhf {
  #   owner = "MaziyarPanahi";
  #   repo = "gemma-3-4b-it-GGUF";
  #   name = "gemma-3-4b-it.Q8_0.gguf";
  #   hash = "sha256-rbJ8sTZV3ALfHNwZMmS5X1NcPXzA4/mH/YUMfnMAcfI=";
  # };

  gemma3 = fetchhf {
    owner = "ggml-org";
    repo = "gemma-3-4b-it-GGUF";
    name = "gemma-3-4b-it-Q4_K_M.gguf";
    hash = "sha256-iC6NLbRNxVT7DqUHfLfkvEnnNCofDaV5AcCALqIaCGM=";
  };

  # https://huggingface.co/cjpais/llava-1.6-mistral-7b-gguf/tree/main
  llava = fetchhf {
    owner = "cjpais";
    repo = "llava-1.6-mistral-7b-gguf";
    name = "llava-v1.6-mistral-7b.Q6_K.gguf";
    hash = "sha256-MYJhcP+i6AgLvNdMrHGPkGSE/VpZiVVQ75TBuqSZdZU=";
  };

  # For later testing
  qwen3 = fetchhf {
    owner = "bartowski";
    repo = "Qwen_Qwen3-0.6B-GGUF";
    name = "Qwen_Qwen3-0.6B-Q4_K_M.gguf";
    hash = "sha256-ms/B4AExHzS0JSABtiby5GbVkqQgZfZlcb/zeQ1OGxQ=";
  };

  gpt-oss = fetchhf {
    owner = "ggml-org";
    repo = "gpt-oss-20b-GGUF";
    name = "gpt-oss-20b-mxfp4.gguf";
    hash = "sha256-vjemNqyg/BquDTIyX4L2tNIUlfBoI7X7wYmK4DA+mTU=";
  };

  llama-cpp-shared = rec {
    version = "7406";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "b${version}";
      hash = "sha256-3qGJ/SFJzg69xvUtc/RqPOtUOFStpcSwJaJGXxeWTwc=";
      leaveDotGit = true;
      postFetch = ''
        git -C "$out" rev-parse --short HEAD > $out/COMMIT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };
  };

  llama-swap = (
    pkgs.llama-swap.overrideAttrs (old: rec {
      version = "176";
      passthru.ui = old.passthru.ui;
      passthru.npmDepsHash = "sha256-RKPcMwJ0qVOgbTxoGryrLn7AW0Bfmv9WasoY+gw4B30=";
      vendorHash = "sha256-/EbFyuCVFxHTTO0UwSV3B/6PYUpudxB2FD8nNx1Bb+M=";
      src = pkgs.fetchFromGitHub {
        owner = "mostlygeek";
        repo = "llama-swap";
        tag = "v${version}";
        hash = "sha256-nfkuaiEITOmpkiLft3iNW1VUexHwZ36c8gwcQKGANbQ=";
        leaveDotGit = true;
        postFetch = ''
          cd "$out"
          git rev-parse HEAD > $out/COMMIT
          # '0000-00-00T00:00:00Z'
          date -u -d "@$(git log -1 --pretty=%ct)" "+'%Y-%m-%dT%H:%M:%SZ'" > $out/SOURCE_DATE_EPOCH
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
    })
  );

  # TODO: testing out blas vs sycl/intel support for llama.cpp running models,
  # maybe I do a build that uses both?
  llama-cpp-blas =
    (pkgs.llama-cpp.override {
      cudaSupport = false;
      rocmSupport = false;
      metalSupport = false;
      blasSupport = true;
    }).overrideAttrs
      (
        old:
        {
          # cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          #   "-DGGML_NATIVE=ON"
          # ];
          # preConfigure = ''
          #   export NIX_ENFORCE_NO_NATIVE=0
          #   ${old.preConfigure or ""}
          # '';
        }
        // llama-cpp-shared
      );

  # TODO: Figure out how to get this beast to build, I need oneMath somehow for compiler support.
  # This is as is tradition a future mitch problem.
  llama-cpp-intel = pkgs.llama-cpp.overrideAttrs (
    old:
    {
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
    }
    // llama-cpp-shared
  );
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
      default = llama-swap;
      description = "Default package derivation to use for llama-swap";
    };
    llamaCpppkg = mkOption {
      type = types.package;
      default = llama-cpp-blas;
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

    #    systemd.services.llama-swap.serviceConfig.ExecStart = "${lib.getExe pkgs.llama-cpp} --listen ${cfg.ollamaCname}:8080 --config"
    services.llama-swap = {
      enable = true;
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
            gemma3 = {
              cmd = "${llama-server} --port \${PORT} -m ${gemma3} -c 131072";
              ttl = longTtl;
            };
            llava = {
              cmd = "${llama-server} --port \${PORT} -m ${llava}";
              ttl = longTtl;
            };
            gpt-oss-20b = {
              cmd = "${llama-server} --port \${PORT} -m ${gpt-oss}";
              ttl = shortTtl;
            };
            qwen3 = {
              cmd = "${llama-server} --port \${PORT} -m ${qwen3}";
              ttl = shortTtl;
            };
          };
        };
    };
  };
}
