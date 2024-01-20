{
  description = "mitchty nixos flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # Not overriding inputs.nixpkgs due to
    # https://github.com/nix-community/disko/blob/master/flake.nix#L4
    disko.url = "github:nix-community/disko";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , nixos-generators
    , deploy-rs
    , agenix
    , disko
    , ...
    }:
    let
      # Current ssh ed25519 pub key to use when sshing into the autoinstaller
      # setup if I need to for god knows why, probably debugging shenanigans.
      pubKey = (builtins.readFile ./secrets/crypt/id_ed25519.pub);

      inherit (nixpkgs.lib) attrValues makeOverridable nixosSystem mkForce mkDefault;

      system = "x86_64_linux";
      pkgs = import nixpkgs {
        inherit system;
      };

      # For the future...
      supportedSystems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Setup an auto installing iso image using disko
      mkAutoDiskoIso = pkgs: nixos-generators.nixosGenerate {
        inherit pkgs;
        format = "install-iso";
        # We always include nixos disko modules for install isos
        modules = [
          disko.nixosModules.default
        ];
      };

      mkAutoInstaller = nixosConfiguration:
        let
          pkgs = nixosConfiguration.pkgs;
          nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";
        in
        (nixosSystem {
          system = pkgs.system;
          modules =
            [
              ({ pkgs, ... }: {
                # Let 'nixos-version --json' know about the Git revision
                # of this flake.
                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

                # Don't flush to the backing store, reduces possible writes to
                # the device backing the iso if any. More for stuff like the pi/sd cards et al
                environment.etc."systemd/pstore.conf".text = ''
                  [PStore]
                  Unlink=no
                '';

                # Network configuration.
                networking = {
                  # Don't log failed connections to the console
                  firewall.logRefusedConnections = mkDefault false;
                  # Since I normally only build one thing at a time give it the
                  # same dhcp hostname so dns can pick it up.
                  hostName = "autoinstall";

                  firewall.allowedTCPPorts = [ 22 ];
                };

                nix = {
                  settings = {
                    substituters = [
                      # "http://cache.cluster.home.arpa"
                      "https://cache.nixos.org"
                      "https://nix-community.cachix.org"
                    ];
                    trusted-public-keys = [
                      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                    ];
                  };

                  # Lets things download in parallel
                  extraOptions = ''
                    binary-caches-parallel-connections = 100
                    experimental-features = nix-command flakes
                  '';
                };
                isoImage.forceTextMode = true;
                isoImage.squashfsCompression = "zstd -Xcompression-level 9";

                boot.supportedFilesystems = [ "xfs" "zfs" "ext4" ];

                # No docs on the install iso
                documentation.enable = false;
                documentation.nixos.enable = false;

                services.getty.autologinUser = pkgs.lib.mkForce "root";
                environment = {
                  variables = {
                    # Since we have no swap, have the heap be a bit less extreme
                    # and gc sooner if we end up on a system with less ram e.g.
                    # arm rpi
                    GC_INITIAL_HEAP_SIZE = "1M";
                  };
                  systemPackages = with pkgs; [
                    btop
                    busybox
                    coreutils
                    curl
                    dmidecode
                    dropwatch
                    flashrom
                    iotop
                    jq
                    linux-firmware
                    linuxPackages.cpupower
                    linuxPackages.perf
                    lvm2
                    lvm2.bin
                    mdadm
                    nixpkgs-fmt
                    parted
                    pciutils
                    powertop
                    stdenv
                    strace
                    tcpdump
                    thin-provisioning-tools
                    utillinux
                    vim
                  ];
                  # (pkgs.writeShellScriptBin "diskoScript" ''
                  #   ${nixosConfiguration.config.system.build.diskoScript}
                  #   nixos-install --no-root-password --option substituters "" --no-channel-copy --system ${nixosConfiguration.config.system.build.toplevel}
                  #   reboot
                  # '')
                };

                # Effectively "run" this on the install iso's first tty only
                programs.bash.interactiveShellInit = ''
                  if [ "$(tty)" = "/dev/tty1" ]; then
                    echo autoinstall would run here if it existed yet | tee /dev/console
                    shutdown now
                  fi
                '';
                # I want my magic sysrq triggers to work for this stuff if for
                # some reason I need to middle finger things
                boot.kernel.sysctl = {
                  "kernel.sysrq" = 1;
                };

                # For installation shenanigans make sure /dev/console dumps to
                # the first serial console and that we copy off kernel stuff to
                # ram "just in case" as well flash related settings to make sure
                # we reduce any writes to removable media that may be present.
                boot.kernelParams = [
                  "boot.shell_on_fail"
                  "console=ttyS0,115200n8"
                  "copytoram=1"
                  "delayacct"
                  "intel-spi.writeable=1"
                  "iomem=relaxed"
                ];

                users = {
                  users.nixos.isNormalUser = true;
                  extraUsers = {
                    root.openssh.authorizedKeys.keys = [ pubKey ];
                    nixos.openssh.authorizedKeys.keys = [ pubKey ];
                  };
                };

                # Let me ssh in by default
                services.openssh = {
                  enable = true;
                  settings = {
                    PermitRootLogin = "yes";
                  };
                };
              })
            ] ++ [
              "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            ];
        }).config.system.build.isoImage;

    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          rec {
            vmZfsMirrorSystem = (makeOverridable nixosSystem) rec {
              inherit system;
              modules = [ ];
              specialArgs = {
                inherit inputs;
              };
            };
            vmZfsMirror = mkAutoDiskoIso pkgs;
            # 2 disk auto mirror setup in disko setup for qemu vm
            # testing/validation (re)uses nixosConfiguration ^^^ for disko
            # install. Note all disko setup is opinionated in that its setup to
            # only use labels or partlabels that lets us create what would be in
            # hardware-configuration.nix ourselves which seems to only include
            # uuid device by default and I want to make that mostly transparent.
            #
            # For now only validating efi bootable stuff out of laziness and
            # need as I can use systemctl reboot --firmware-setup to make it
            # easy to pick disparate devices to test booting off of to manually
            # validate (for now) until at least I can better figure out how to
            # set efi vars to change devices once I figure that out.
            isoZfsTest = mkAutoInstaller vmZfsMirrorSystem;
            default = isoZfsTest;
          });
      checks = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            # Ensure all our formatting is kosher in nix lande for now.
            formatting =
              pkgs.writeShellApplication
                {
                  name = "formatting";
                  runtimeInputs = with pkgs; [
                    nixpkgs-fmt
                    deadnix
                  ];
                  text = ''
                    nixpkgs-fmt --check "$@"
                    #            deadnix --edit "$@"
                  '';
                };
            shell = pkgs.writeShellApplication
              {
                name = "shellchecks";
                runtimeInputs = with pkgs; [
                  shellcheck
                  shellspec
                  ksh
                  oksh
                  zsh
                  bash
                  findutils
                  # abusing python3 for pty support cause shellspec needs it for
                  # some output or another to run in nix given nix runs top most
                  # pid without a pty. We could do this any way we can get a pty
                  # so that shellspec can run but this is fine.
                  python3
                ];
                text = ''
                  shellcheck --severity warning --shell sh "$(find ${./.} -type f -name '*.sh')" --external-sources
                  for shell in ${pkgs.ksh}/bin/ksh ${pkgs.oksh}/bin/ksh ${pkgs.zsh}/bin/zsh ${pkgs.bash}/bin/bash; do
                                        ${pkgs.python3}/bin/python3 -c 'import pty; pty.spawn("${pkgs.shellspec}/bin/shellspec -c ${./.} --shell '$shell' -x")'
                                      done
                '';
                # deploy-rs =
                #   builtins.mapAttrs
                #     (deployLib: deployLib.deployChecks self.deploy)
                #     deploy-rs.lib;
              };
          }
        );
    };
}
