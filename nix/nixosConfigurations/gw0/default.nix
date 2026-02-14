{ inputs, lib, ... }:
let
  shortHost = "gw0";
in
{
  system = "x86_64-linux";

  modules = [
    {
      # Host metadata for secrets generation
      mitchty.secrets = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyjyOCeUEtKb7hLISbPzwkrrSDKQU5JGJ1R1Sw7MZga";
        tags = [
          "wireguard"
          "nixos"
        ];
      };
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
          ssh-mitch
          user-root
          ssh-root
          user-mitch-compat
          podman
          #          nas TODO: fix this to work with media as well, will move the base for all media from /nas/media to /nas/srv/media for serving needs
          node-exporter
          promtail
          debug
          power
          power-intel
          nix-offload
          fw
          blocklist
          ncps
          router
          homer
          #          ip-hacks
          ociregistry
          wireguard
          atuin
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
                  git
                  age
                  debug
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
        ])
        ++ [
          ./diskconfig.nix
        ];

      services = {
        common.mosh.enable = true;

        mitchty = {
          age.enable = true;
          homer.enable = true;
          blocklist.enable = true;
          router = {
            enable = true;
            wanIface = "enp4s0";
            lanIface = "br0";
            dnsUpdate = {
              enable = true;
              record = "home.mitchty.net";
              interval = "1h";
            };
          };
          promtail.enable = true;
          node-exporter = {
            enable = true;
            iface = "br0";
          };
          ncps = {
            enable = true;
            iface = "br0";
          };
          ociregistry = {
            enable = true;
            port = 12345;
            bindAddress = "10.10.10.140";
          };
          atuin = {
            enable = true;
            iface = "br0";
          };
          wireguard = {
            enable = true;
            role = "server";
            address = [ "192.168.255.1/24" ];
            listenPort = 51820;
            privateKeyFile = "secrets/wireguard/prv/gw0";
            dns = [ "10.10.10.1" ];
            enableNat = true;
            natInterface = "br0";
            natSubnet = "192.168.255.0/24";
            peers = [
              # iphone
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/ip/publickey}";
                allowedIPs = [
                  "192.168.255.7/32"
                ];
                # Roaming crap sends their own keepalives, we don't send one to them obvs
              }
              # mbp laptop
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/mbp/publickey}";
                allowedIPs = [
                  "192.168.255.6/32"
                ];
                # Roaming crap sends their own keepalives, we don't send one to them obvs
              }
              # wm2 laptop
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/wm2/publickey}";
                allowedIPs = [
                  "192.168.255.2/32"
                ];
              }
              # plx - wired
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/plx/publickey}";
                allowedIPs = [
                  "192.168.255.3/32"
                ];
                persistentKeepalive = 25;
              }
              # ark  - wired
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/ark/publickey}";
                allowedIPs = [
                  "192.168.255.4/32"
                ];
                persistentKeepalive = 25;
              }
              # rtx - wired
              {
                publicKey = "${builtins.readFile ../../../crypt/wireguard/rtx/publickey}";
                allowedIPs = [
                  "192.168.255.5/32"
                ];
                persistentKeepalive = 25;
              }
            ];
          };
        };
      };

      # Everything here is now in router.nix, here in some odd reason if I
      # want/need to uncomment.
      # networking.interfaces = {
      #   enp4s0 = {
      #     useDHCP = true;
      # };
      # br0 = {
      #   ipv4.addresses = [
      #     {
      #       address = "10.10.10.2";
      #       prefixLength = 24;
      #     }
      #   ];
      # };
      # };
      # bridges.br0.interfaces = [ "enp4s0" "enp5s0" "enp6s0" ];

      diskConfig.disks = [
        "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300325L"
        "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_256GB_S2GLNXAH300329W"
      ];

      system.stateVersion = "25.05";

      networking = {
        hostName = shortHost;

        dhcpcd.extraConfig = ''
          interface enp4s0
          metric 10
        '';
        wireguard.enable = true;
        # networkmanager.unmanaged = [ "interface-name:wg0" ];
        # firewall = {
        #   interfaces.wg0 = {
        #     allowedTCPPortRanges = [
        #       {
        #         from = 0;
        #         to = 65535;
        #       }
        #     ];
        #   };
        #   allowedUDPPorts = [ 51820 ];
        # };
        # interfaces.wg0 = {
        #   useDHCP = false;
        # };
        # wg-quick.interfaces.wg0 =
        #   let
        #     intNet4 = "10.10.10.0/24";
        #   in
        #   {
        #     address = [ "192.168.255.1/32" ];
        #     # Use internal dns server for the adblock network blocking
        #     dns = [ "10.10.10.1" ];
        #     #dns = [ "1.1.1.1" ];
        #     privateKey = "${builtins.readFile ../../../crypt/wireguard/gw0/privatekey}";

        #     listenPort = 51820;

        #     peers = [
        #       #       # Roaming capable peers
        #       #       #
        #       #       # m4max mbp
        #       #       {
        #       #         publicKey = "${builtins.readFile ../../../crypt/wireguard/mbp/publickey}";
        #       #         allowedIPs = [
        #       #           "0.0.0.0/0" # When mobile
        #       #           "::/0" # When mobile
        #       #           #                  intNet4
        #       #         ];
        #       #         # endpoint only whilst not roaming
        #       #         #                endpoint = "home.mitchty.net:51820";
        #       #         persistentKeepalive = 25;
        #       #       }
        #       #       # TODO winmax2 2023 wm2
        #       # rtx desktop chungus
        #       # {
        #       #   publicKey = "${builtins.readFile ../../../crypt/wireguard/rtx/publickey}";
        #       #   allowedIPs = [
        #       #     #"10.10.10.11/32"
        #       #     "0.0.0.0/0" # When mobile
        #       #     #"::/0" # When mobile
        #       #     #intNet4
        #       #   ];
        #       #   # endpoint only whilst not roaming
        #       #   #                endpoint = "rtx.home.arpa:51820";
        #       #   persistentKeepalive = 25;
        #       # }
        #     ];
        #   };
      };

      boot = {
        tmp.tmpfsSize = "40%";

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
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
