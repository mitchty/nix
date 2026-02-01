{
  pkgs,
  lib,
  config,
  ...
}:
let
  update-mac = pkgs.writeShellScriptBin "update-mac" "$SHELL ${../../src/update-mac.sh} enp4s0";
  update-ip = pkgs.writeShellScriptBin "update-ip" "$SHELL ${../../src/randmacaddr.sh} enp4s0";
  update-dns = pkgs.writeShellScriptBin "update-dns" "dns-update --record home.mitchty.net --ip $(cat /var/tmp/wanip)";

  # Not a great name but eh
  stateDir = "/var/state";
  macFile = "${stateDir}/mac";
  ipFile = "${stateDir}/ip";
  triggerFile = "${stateDir}/newip";
in
{
  age.secrets = {
    "secrets/dns/home.mitchty.net" = {
      file = ../../secrets/dns/home.mitchty.net.age;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root"
  ];

  # THIS NEEDS SOME MORE THINKIN
  #
  # Ok so I should probably split this apart into a few different sections. I
  # need to separate out getting a new mac address from the ip to the update of
  # dns. I also need to have the mac address randomization persist on reboots.
  systemd = {
    services = {
      "random-mac" = {
        description = "Update wan macaddr";
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
                  update-mac
                ];
                nativeBuildInputs = [
                  pkgs.makeWrapper
                ];
                postBuild = ''
                  wrapProgram $out/bin/update-mac --prefix PATH : "${lib.makeBinPath paths}"
                '';
              };
            in
            "${script}/bin/update-mac";
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
        "update-mac" = {
          description = "update-mac path trigger";
          pathConfig = {
            PathExists = macFile;
          };
          wantedBy = [ "multi-user.target" ];
          after = [ "dhcpcd.service" ];
        };
        "update-ip" = {
          description = "update-ip path trigger";
          pathConfig = {
            PathExists = triggerFile;
          };
          wantedBy = [ "multi-user.target" ];
          after = [ "dhcpcd.service" ];
        };
        "update-dns" = {
          description = "update cloudflare dns path trigger";
          pathConfig = {
            PathModified = ipFile;
          };
        };
      };
    };
  };
}
