{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports =
    builtins.map (mod: inputs.${mod}.nixosModules.${mod}) [
      "disko"
      "home-manager"
    ]
    ++ [
      "${toString inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ]
    ++ (with inputs.self.nixosModules; [
      ssh-root
      ssh-nixos
    ]);

  # I don't want docs on the iso system derivation. Don't need em wasting space/time.
  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };

  # By default use lz4 compression, each image can customize the compression
  # with module imports.
  isoImage.squashfsCompression = lib.mkDefault "lz4";

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    variables = {
      # Since we have no swap, have the heap be a bit less extreme
      GC_INITIAL_HEAP_SIZE = "1M";

      # if I need it...
      EDITOR = "vi";
    };
  };

  users = {
    mutableUsers = false;
    users.nixos = {
      isNormalUser = true;
      description = "nixos install user";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      # This is a test vm only used to test out disk/install automation. Its not
      # getting out/exposed to the outside world ever.
      # echo nixos | openssl passwd -6 -stdin -salt vmtestsalt
      hashedPassword = "$6$vmtestsalt$RU13pQq.NolDt0ZFHiLVzYNjIdTY1aj43jklM/6hrge1NAIosvc.W16.dLf5CwsSaSlbCg0pqupZdkLQdf0/z0";
    };
  };

  # Let me ssh in by default
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "yes";
    };
  };

  # Don't flush to the backing store
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Unlink=no
  '';

  # TODO: moveme/determine common settings
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
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
    };

    # Lets things download in parallel
    #
    # extra-nix-path is to allow disko -m mount to work
    extraOptions = ''
      binary-caches-parallel-connections = 100
      extra-nix-path = nixpkgs=flake:nixpkgs
    '';
  };

  # TODO: whats common here exactly?
  boot = {
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "vm.overcommit_memory" = lib.mkForce 1;
    };
    kernelParams = [
      "boot.shell_on_fail"
      "console=ttyS0,115200n8"
      "console=tty0" # fallback somehow if serial no work somehow?
      "delayacct"
      "intel-spi.writeable=1"
      "iomem=relaxed"
    ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };

  # Use only the final shell not crappy bash
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Abuse the nixos user activation script to do the install work
  system.activationScripts.nixosUserInit =
    let
      userName = "nixos";
      nixosHomeDir = "/home/" + "${userName}/";
      rootHomeDir = "/root/";
    in
    # TODO: integrate home-manager into the iso setup? For now lets just get
    # this shit working first.
    ''
      for user in root nixos; do
        if [ $user == "root" ]; then
          homedir="/root/"
          group=root
        else
          homedir="/home/$user/"
          group=users
        fi

        install -m644 --owner $user --group $group ${./installer-zshrc} $homedir/.zshrc
        install -m644 --owner $user --group $group /dev/null $homedir/.zsh_history
      done
    '';

  # The autoinstall script is setup in the iso configuration.nix file(s) as they
  # have the derivation data.
  systemd.services.autoinstall = {
    description = "NixOS Autoinstall";
    wantedBy = [ "multi-user.target" ];
    # wantedBy = [ "multi-user.target" ];
    # TODO: wait for network instead? Not a huge deal it installs in airgap anyway.
    #        wantedBy = [ (if somedumcondition then "network-online.target" else "multi-user.target") ];
    after = [
      "network.target"
      "polkit.service"
    ];

    path = with pkgs; [
      "/run/current-system/sw/"
      "/usr/bin/"
      "${systemd}/bin/"
      "${e2fsprogs}/bin/"
    ];

    # If the disko-install worked reboot into the firmware setup so I can move
    # things along manually
    #
    # TODO: reboot only in vm's otherwise into firmware?
    script = ''
      set -eux
      autoinstall
      sudo systemctl reboot --firmware-setup
      # sudo systemctl reboot
    '';

    # This should only be ran when on the iso installer. So don't ever include
    # /iso as a path in a setup dumass.
    unitConfig.ConditionPathExists = "/iso";

    serviceConfig = {
      Type = "oneshot";
    };
  };
}
