{ config, ... }: {
  config = {
    documentation.nixos.enable = false;

    # If for any reason I need to get at the derivation that led to this
    # generation, save off the input source.
    environment.etc."current-nixos".source = ./..;
    # system.nixos.label = concatStringsSep "-" ((sort (x: y: x < y) cfg.tags) ++ [ "${cfg.version}.${self.sourceInfo.shortRev or "dirty"}" ]);

    # Lets let arm stuff run easily
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Set your time zone.
    time.timeZone = "America/Chicago";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    # Default queueing discipline will be controlled delay
    boot.kernel.sysctl."net.core.default_qdisc" = "fq_codel";

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs = {
      mtr.enable = true;
      # zsh for a login shell, bash is silly
      zsh.enable = true;
    };

    networking.enableIPv6 = true;

    services = {
      # chrony for ntp
      chrony = {
        enable = true;
        servers = [
          "pool.ntp.org"
          "pool.ntp.org"
          "pool.ntp.org"
          "time.apple.com"
        ];
      };
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "yes";
        };
      };
      journald.extraConfig = ''
        MaxFileSec=1day
        MaxRetentionSec=1week
      '';
    };
  };
}
