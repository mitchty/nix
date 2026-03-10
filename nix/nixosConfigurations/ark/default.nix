{
  inputs,
  lib,
  ...
}:
let
  shortHost = "ark";
  # iface = "eno1";
  iface = "enp6s0";
  commonMonitoring = {
    enable = true;
    #    iface = "enp88s0";
    inherit iface;
  };
  system = "x86_64-linux";

  # Host metadata for secrets generation
  hostSecrets = {
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFFvNk88g2x8R5cK1K+iVGQT1Lu1IFKZwSp75s2xegB";
    tags = [
      "wireguard"
      "cifs"
      "backup"
      "nixos"
    ];
  };
in
{
  inherit system;

  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = hostSecrets;

      # TODO: Ok so to make sure I don't get infinite recursion around these
      # here parts.
      #
      # Need to brain a simple way to approach module imports so that an import
      # only occurs once and only once.
      #
      # I'm thinking the nixosModules will contain everything *but* the imports
      # and then I can just setup the imports here?
      #
      # Exception to this rule is disko, that is in common as an import as
      # everything will have it. Actually that will be the *only* exception to
      # this "rule".
      imports =
        (with inputs.self.nixosModules; [
          common
          console-normal
          user-mitch
          user-mitch-compat
          ssh-mitch
          user-root
          ssh-root
          podman
          #          nas TODO: fix this to work with media as well, will move the base for all media from /nas/media to /nas/srv/media for serving needs
          node-exporter
          promtail
          loki
          prometheus
          grafana
          media
          backup
          debug
          virtualization
          power
          power-intel
          #          nix-offload
          fw
          # nvidia-hack
          gpu-intel
          # ai
          llama-swap
          wireguard
          age
        ])
        ++ (with inputs.self.crossplatformModules; [
          common
          mosh
        ])
        ++ [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "bak";

              users.mitch = {
                home = {
                  username = "mitch";
                  homeDirectory = "/Users/mitch";
                  stateVersion = "25.05";
                };
                imports = [
                  inputs.agenix.homeManagerModules.default
                ]
                ++ (with inputs.self.homeModules; [
                  common
                  sh
                  tmux
                  yt
                  git
                  age
                  debug
                  development
                  kopia
                ]);

                mitchty.sh.historyBackend = "atuin";
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-intel
          common-gpu-intel
          #          common-gpu-nvidia-nonprime
        ])
        ++ [
          ./diskconfig.nix
        ];

      # enp88s0/enp91s0 TODO: determine which of these has the built in ilom
      # thing, can maybe use that instead of pikvm for this one node to not have
      # so many pikvms and such.
      services = {
        karakeep = {
          enable = true;
          browser.enable = true;
          extraEnvironment = {
            NEXTAUTH_URL = "http://karakeep.home.arpa:3000";
            HOSTNAME = "10.10.10.224";
            DISABLE_SIGNUPS = "true";
            DISABLE_NEW_RELEASE_CHECK = "true";
            CRAWLER_FULL_PAGE_ARCHIVE = "true";
            OCR_CACHE_DIR = "/tmp";
            CRAWLER_FULL_PAGE_SCREENSHOT = "true";
            KARAKEEP_PYTHON_API_VERBOSE = "true";
            SEARCH_NUM_WORKERS = "4";
            WEBHOOK_NUM_WORKERS = "1";
            ASSET_PREPROCESSING_NUM_WORKERS = "1";
            RULE_ENGINE_NUM_WORKERS = "1";
            #            OLLAMA_BASE_URL = "http://slow-ollama.home.arpa:11343";
            # OLLAMA_BASE_URL = "http://localhost:11343/openapi";
            # OPENAI_BASE_URL = "http://localhost:11343/v1";
            OPENAI_BASE_URL = "http://llama.home.arpa:11343/v1";
            OPENAI_API_KEY = "no-key";
            # OLLAMA_BASE_URL = "http://ollama.home.arpa:11434";
            INFERENCE_TEXT_MODEL = "gemma3";
            INFERENCE_IMAGE_MODEL = "llava";
            # These seem to take 1-2ish minutes per bookmark when run against blas compiled llama-cpp
            # Default I think is 30 seconds or whatever. Was getting 502's all the time in llama-swap till I fixed this higher.
            #
            # Slow... but for ai tagging on a system that draws like 10watts under load... not a problem really for this task.
            #
            # If I need to retag a lot super fast I can always use ollama/etc... on the 4090 box temporarily.
            #
            # Ai tags taking minutes isn't a huge loss to me.
            INFERENCE_JOB_TIMEOUT_SEC = "600";
            # CRAWLER_VIDEO_DOWNLOAD = "true";
            # CRAWLER_VIDEO_DOWNLOAD_MAX_SIZE = "true";
            # CRAWLER_VIDEO_DOWNLOAD_TIMEOUT_SEC = "3600";
            # CRAWLER_YTDLP_ARGS = "-f%%bestvideo*+bestaudio/best";
          };
        };

        common.mosh.enable = true;

        mitchty = {
          age.enable = true;
          promtail.enable = true;
          node-exporter = commonMonitoring;
          loki = commonMonitoring;
          prometheus = commonMonitoring;
          grafana = commonMonitoring;
          media = commonMonitoring // {
            services = true;
          };
          # ai = commonMonitoring // {
          #   enable = true;
          #   iface = "enp6s0";
          #   ollamaCname = "slow-ollama.home.arpa";
          #   ollamaIp = "10.10.10.222";
          #   ollamaPackage = unstable-pkgs.ollama;
          #   owuiCname = "slow-open-webui.home.arpa";
          #   owuiIp = "10.10.10.223";
          # };
          llama-swap = commonMonitoring // {
            enable = true;
          };
          wireguard = {
            enable = true;
            role = "client";
            address = [ "192.168.255.4/24" ];
            listenPort = 51820; # Required for peer-to-peer mesh
            privateKeyFile = "secrets/wireguard/prv/ark";
            dns = [ "10.10.10.1" ];
            peers = [
              # gw0 gateway/router
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/gw0/publickey}";
                allowedIPs = [
                  "192.168.255.1/32"
                  "192.168.255.6/32"
                  "192.168.255.2/32"
                ];
                endpoint = "10.10.10.1:51820";
                persistentKeepalive = 25;
              }
              # plx - wired
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/plx/publickey}";
                allowedIPs = [
                  "192.168.255.3/32"
                ];
                endpoint = "10.10.10.14:51820";
                persistentKeepalive = 25;
              }
              # rtx - wired
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/rtx/publickey}";
                allowedIPs = [
                  "192.168.255.5/32"
                ];
                endpoint = "10.10.10.11:51820";
                persistentKeepalive = 25;
              }
            ];
          };
        };

        # TODO: setup forgejo runners to build stuff for me?
        forgejo = {
          enable = true;
          database.type = "sqlite3";
          lfs.enable = true;
          settings = {
            server = rec {
              DOMAIN = "git.home.arpa";
              ROOT_URL = "http://${DOMAIN}:3000";
              #              HTTP_PORT = 80;
              HTTP_ADDR = "10.10.10.227";

              # To use ssh to send/receive git repos
              START_SSH_SERVER = true;
              SSH_PORT = 2222;
              SSH_LISTEN_HOST = "10.10.10.227";
              SSH_LISTEN_PORT = 2222;
            };
            # Comment out if first run or to setup another user
            service.DISABLE_REGISTRATION = true;
            # Turn me on once I get home.arpa acme working again
            session.COOKIE_SECURE = false;
          };
        };

        openssh.settings.AcceptEnv = "GIT_PROTOCOL";
      };

      networking = {
        nameservers = [
          "10.10.10.1"
          #          "1.1.1.1"
        ];
        defaultGateway = {
          address = "10.10.10.1";
          interface = "${iface}";
        };
        # Set the 10g nic up to have a metric cost so this stuff behaves
        # sane...er I hope.
        # dhcpcd.extraConfig = ''
        #   interface enp3s0f1np1
        #   metric 1000
        # '';
        interfaces = {
          "${iface}" = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = "10.10.10.253";
                prefixLength = 24;
              }
              {
                address = "10.10.10.224";
                prefixLength = 24;
              }
              {
                address = "10.10.10.227";
                prefixLength = 24;
              }
            ];
          };
        };

        firewall = {
          interfaces = {
            "${iface}" = {
              allowedTCPPorts = [
                2222
                3000
              ];
            };
          };
        };
      };

      # Needed for nixos-hardware common-gpu-nvidia
      # Ref:
      #  Failed assertions:
      # - You must configure `hardware.nvidia.open` on NVIDIA driver versions >= 560.
      # It is suggested to use the open source kernel modules on Turing or later GPUs (RTX series, GTX 16xx), and the closed source modules otherwise.
      #      services.xserver.videoDrivers = [ "nvidia" ];

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X707714B"
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X700496V"
      ];
      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
        # Make sure this interface doesn't respond to arp and eff everything up
        # that is on enp88s0
        kernel.sysctl = {
          "net.ipv4.conf.enp3s0f1np1.arp_ignore" = 1;
        };
        # If this boi needs to build stuff let /tmp be sized enough to build the
        # kernel and some change at 48GiB of rams. The intel box isn't super
        # fast but I'm more abusing it to build iso images and copying stuff
        # directly to the nas over 10g.
        tmp.tmpfsSize = "80%";

        loader.systemd-boot.enable = true;

        # Had to brain these out from lspci -k and just hulk smashed every
        # module in the chain in here.
        #
        # TODO: since I build my own kernel anyway, why don't I just smash all
        # this crap into a custom defconfig instead there and compile this in
        # not as a module at all?
        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usbhid"
          "usb_storage"
          "sr_mod"
        ];
        kernelModules = [ "kvm-intel" ];
        kernelParams = [
          "console=tty0"
        ];
      };

      hardware.nvidia = {
        open = lib.mkForce true;
        #        nvidiaSettings = true;
        modesetting.enable = true;
        powerManagement.enable = true;

        # This kinda craps in nvidia-hack now rest is "normal" settings
        # package = pkgs.kernelPackages.nvidiaPackages.mkDriver {
        #   version = "570.181";
        #   sha256_64bit = "sha256-8G0lzj8YAupQetpLXcRrPCyLOFA9tvaPPvAWurjj3Pk=";
        #   sha256_aarch64 = "sha256-1pUDdSm45uIhg0HEhfhak9XT/IE/XUVbdtrcpabZ3KU=";
        #   openSha256 = "sha256-U/uqAhf83W/mns/7b2cU26B7JRMoBfQ3V6HiYEI5J48=";
        #   settingsSha256 = "sha256-iBx/X3c+1NSNmG+11xvGyvxYSMbVprijpzySFeQVBzs=";
        #   persistencedSha256 = "sha256-RoAcutBf5dTKdAfkxDPtMsktFVQt5uPIPtkAkboQwcQ=";
        # };
      };

      nixpkgs = {
        config = {
          allowUnfree = true;
        };
        #        config.cudaSupport = true;
        hostPlatform = "x86_64-linux";
      };
    }
  ];
}
