{ lib, pkgs, ... }:
let
  sshPubKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7"
  ];
in
{
  # I don't want docs on the iso system derivation. Don't need em wasting space/time.
  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };

  users = {
    mutableUsers = false;
    users.root = {
      openssh.authorizedKeys.keys = sshPubKeys;
    };
    users.nixos = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshPubKeys;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
    };
  };
  boot = {
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "vm.overcommit_memory" = lib.mkForce 1;
    };
    kernelParams = [
      "boot.shell_on_fail"
      "console=ttyS0,115200n8"
      #              "console=tty0" # fallback somehow if serial no work somehow?
      "copytoram=1"
      "delayacct"
      "intel-spi.writeable=1"
      "iomem=relaxed"
    ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      # iso uses grub installed system uses systemd-boot
      grub.memtest86.enable = true;
      systemd-boot.memtest86.enable = true;
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
    # TODO: integrate home-manager into the iso setup? For now lets just get this shit working first.
    ''
      for user in root nixos; do
        if [ $user == "root" ]; then
          homedir="/root/"
          group=root
        else
          homedir="/home/$user/"
          group=users
        fi

        install -m644 --owner $user --group $group ${./zshrc} $homedir/.zshrc
        install -m644 --owner $user --group $group /dev/null $homedir/.zsh_history
      done
    '';

}
