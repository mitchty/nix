{
  inputs,
  lib,
  ...
}:
let
  shortHost = "ark";
  commonMonitoring = {
    enable = true;
    iface = "enp88s0";
  };
  system = "x86_64-linux";

  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
  unstable-pkgs = unstable.pkgs;
  #  unstable = inputs.nixpkgs-unstable.legacyPackages.${system}.pkgs;
in
{
  inherit system;

  modules = [
    {
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
          ai
          debug
          virtualization
          power
          power-intel
          nix-offload
          fw
          homer
          nvidia-hack
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
              };
            };
          }
        ]
        ++ (with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-intel
          common-gpu-intel
          common-gpu-nvidia-nonprime
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
            OLLAMA_BASE_URL = "http://slow-ollama.home.arpa:11434";
            INFERENCE_TEXT_MODEL = "gemma3";
            INFERENCE_IMAGE_MODEL = "llava";
            OCR_CACHE_DIR = "/tmp";
            # CRAWLER_VIDEO_DOWNLOAD = "true";
            # CRAWLER_VIDEO_DOWNLOAD_MAX_SIZE = "true";
            # CRAWLER_VIDEO_DOWNLOAD_TIMEOUT_SEC = "3600";
            # CRAWLER_YTDLP_ARGS = "-f%%bestvideo*+bestaudio/best";
            CRAWLER_FULL_PAGE_SCREENSHOT = "true";
          };
        };

        common.mosh.enable = true;

        mitchty = {
          homer.enable = true;
          promtail.enable = true;
          node-exporter = commonMonitoring;
          loki = commonMonitoring;
          prometheus = commonMonitoring;
          grafana = commonMonitoring;
          media = commonMonitoring // {
            services = true;
          };
          ai = commonMonitoring // {
            ollamaCname = "slow-ollama.home.arpa";
            ollamaIp = "10.10.10.222";
            ollamaPackage = unstable-pkgs.ollama-cuda;
            owuiCname = "slow-open-webui.home.arpa";
            owuiIp = "10.10.10.223";
          };
        };
      };

      networking = {
        # Set the 10g nic up to have a metric cost so this stuff behaves
        # sane...er I hope.
        dhcpcd.extraConfig = ''
          interface enp3s0f1np1
          metric 1000
        '';
        interfaces = {
          enp88s0 = {
            useDHCP = true;
            ipv4.addresses = [
              {
                address = "10.10.10.224";
                prefixLength = 32;
              }
            ];
          };
          enp3s0f1np1.ipv4 = {
            addresses = [
              {
                address = "10.10.10.242";
                prefixLength = 32;
              }
            ];
            routes = [
              {
                address = "10.10.10.9";
                prefixLength = 32;
                via = "10.10.10.242";
              }
            ];
          };
        };
        firewall = {
          interfaces = {
            "enp88s0" = {
              allowedTCPPorts = [ 3000 ];
            };
          };
        };
      };

      # Needed for nixos-hardware common-gpu-nvidia
      # Ref:
      #  Failed assertions:
      # - You must configure `hardware.nvidia.open` on NVIDIA driver versions >= 560.
      # It is suggested to use the open source kernel modules on Turing or later GPUs (RTX series, GTX 16xx), and the closed source modules otherwise.
      services.xserver.videoDrivers = [ "nvidia" ];

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X707714B"
        "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X700496V"
      ];
      system.stateVersion = "25.05";
      networking.hostName = shortHost;

      boot = {
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
        nvidiaSettings = true;
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
