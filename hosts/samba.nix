{ config, ... }: {
  config = {
    services = {
      samba = {
        enableNmbd = true;
        enable = true;
        securityType = "user";
        extraConfig = ''
          workgroup = WORKGROUP
          server role = standalone server
          dns proxy = no
          vfs objects = catia fruit streams_xattr
          pam password change = yes
          map to guest = bad user
          usershare allow guests = yes
          create mask = 0664
          force create mode = 0664
          directory mask = 0775
          force directory mode = 0775
          follow symlinks = yes
          load printers = no
          printing = bsd
          printcap name = /dev/null
          disable spoolss = yes
          strict locking = no
          aio read size = 0
          aio write size = 0
          vfs objects = catia fruit streams_xattr
          # Security
          client ipc max protocol = SMB3
          client ipc min protocol = SMB2_10
          client max protocol = SMB3
          client min protocol = SMB2_10
          server max protocol = SMB3
          server min protocol = SMB2_10
          # Time Machine
          fruit:delete_empty_adfiles = yes
          fruit:time machine = yes
          fruit:veto_appledouble = no
          fruit:wipe_intentionally_left_blank_rfork = yes
          server string = dfs1
          netbios name = dfs1
          guest account = nobody
          map to guest = bad user
          logging = systemd
        '';
        shares = {
          mnt = {
            path = "/mnt";
            browseable = "yes";
            "valid users" = "mitch";
            "read only" = "no";
            "guest ok" = "no";
            "create mask" = "0644";
            "directory mask" = "0755";
            "veto files" = "/.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/";
            "delete veto files" = "yes";
          };
        };
      };
    };
    services.samba.openFirewall = true;
    networking.firewall.enable = true;
    networking.firewall.allowPing = true;
    networking.firewall.allowedTCPPorts = [ 445 139 ];
    networking.firewall.allowedUDPPorts = [ 137 138 ];
  };
}
