{
  pkgs,
  lib,
  config,
  ...
}:
let
  update-ip = pkgs.writeShellScriptBin "update-ip" ''$SHELL ${../../src/randmacaddr.sh} enp4s0'';
  update-dns = pkgs.writeShellScriptBin "update-dns" ''dns-update --record home.mitchty.net --ip $(cat /var/tmp/wanip)'';
in
{
  age.secrets = {
    "secrets/dns/home.mitchty.net" = {
      file = ../../secrets/dns/home.mitchty.net.age;
    };
  };

  # THIS NEEDS SOME MORE THINKIN
  #
  # Ok so I should probably split this apart into a few different sections. I
  # need to separate out getting a new mac address from the ip to the update of
  # dns. I also need to have the mac address randomization persist on reboots.
  systemd = {
    services = {
      "random-mac" = {
        description = "Update wan dhcp ip";
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.symlinkJoin rec {
                name = "update-ip";
                meta.mainProgram = "update-ip";
                paths = [
                  pkgs.gawk
                  pkgs.coreutils
                  pkgs.iproute2
                  pkgs.systemd
                  update-ip
                ];
                nativeBuildInputs = [
                  pkgs.makeWrapper
                ];
                postBuild = ''
                  wrapProgram $out/bin/update-ip --prefix PATH : "${lib.makeBinPath paths}"
                '';
              };
            in
            "${script}/bin/update-ip";
        };
        wantedBy = [ "multi-user.target" ];
        before = [ "dhcpcd.service" ];
      };
      "update-ip" = {
        description = "Update wan dhcp ip";
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.symlinkJoin rec {
                name = "update-ip";
                meta.mainProgram = "update-ip";
                paths = [
                  pkgs.gawk
                  pkgs.coreutils
                  pkgs.iproute2
                  pkgs.systemd
                  update-ip
                ];
                nativeBuildInputs = [
                  pkgs.makeWrapper
                ];
                postBuild = ''
                  wrapProgram $out/bin/update-ip --prefix PATH : "${lib.makeBinPath paths}"
                '';
              };
            in
            "${script}/bin/update-ip";
        };
        wantedBy = [ "multi-user.target" ];
        before = [ "dhcpcd.service" ];
      };
      "update-dns" = {
        description = "Update wan dns ip";
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.symlinkJoin rec {
                name = "update-dns";
                meta.mainProgram = "update-dns";
                paths = [
                  pkgs.coreutils
                  pkgs.cf-dns-update
                  update-dns
                ];
                nativeBuildInputs = [
                  pkgs.makeWrapper
                ];
                postBuild = ''
                  wrapProgram $out/bin/update-dns --prefix PATH : "${lib.makeBinPath paths}"
                '';
              };
            in
            "${script}/bin/update-dns";
          EnvironmentFile = config.age.secrets."secrets/dns/home.mitchty.net".path;
        };
      };
      paths = {
        "update-ip" = {
          description = "/var/tmp/newip update-ip trigger";
          pathConfig = {
            PathExists = "/var/tmp/newip";
          };
          wantedBy = [ "multi-user.target" ];
          after = [ "dhcpcd.service" ];
        };
        "update-dns" = {
          description = "update cloudflare dns path";
          pathConfig = {
            PathModified = "/var/tmp/wanip";
          };
        };
      };
    };
  };
}
