{ inputs
, lib
, pkgs
, modulesPath
, ...
}:
let
  sshPubKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
  ];

  # For max compression (takes way longer to build an image tho)
  #
  # Compression levels: https://github.com/facebook/zstd/blob/dev/lib/compress/clevels.h#L25
  #
  # Use 5 for testing, 19 for keeping iso size down on a chonky system
  zstdCompressionLevel = 5;
  #
  # Rough size diff with current test data:
  # level 5
  # 6.5G    /nix/store/j82paybcnppn5s9g9pc0pih6f3jknaxx-nixos-24.11.20250408.a62d20d-x86_64-linux.iso/iso/nixos-24.11.20250408.a62d20d-x86_64-linux.iso
  # level 19
  # 6.2G    /nix/store/66az8g3g98crb1zx7wnnkpcjvaanayfa-nixos-24.11.20250408.a62d20d-x86_64-linux.iso/iso/nixos-24.11.20250408.a62d20d-x86_64-linux.iso
  #
  # TODO: add timing tests (warm not cold)
in
{
  # I don't want docs on the iso system derivation. Don't need em wasting space/time.
  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };

  isoImage.squashfsCompression = "zstd -Xcompression-level ${zstdCompressionLevel}";

  # Whilst testing uncomment me (note this takes ages at the end for incremental
  # changes so probably jut nuke this comment and this option entirely its ass)
  #isoImage.squashfsCompression = "lz4";

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
    users.root = {
      openssh.authorizedKeys.keys = sshPubKeys;
    };
    users.nixos = {
      isNormalUser = true;
      description = "nixos install user";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = sshPubKeys;
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
    extraOptions = ''
      binary-caches-parallel-connections = 100
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
      #      "console=tty0" # fallback somehow if serial no work somehow?
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
    wantedBy = [ "network-online.target" ];
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
    ];

    # If the disko-install worked reboot into the firmware setup so I can move
    # things along manually
    #
    # TODO: reboot only in vm's otherwise into firmware?
    script = ''
      set -eux
      autoinstall
      sudo systemctl reboot
    '';

    # This should only be ran when on the iso installer. So don't ever include
    # /iso as a path in a setup dumass.
    unitConfig.ConditionPathExists = "/iso";

    serviceConfig = {
      Type = "oneshot";
    };
  };
}
