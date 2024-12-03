{ config, pkgs, ... }:
let
  fsAutomountOpts = [
    "x-systemd.automount"
    "nofail"
    "x-systemd.idle-timeout=300"
    "x-systemd.mount-timeout=60s"
  ];
  fsCifsPerfOpts = [
    "bsize=8388608"
    "rsize=130048"
    #"cache=loose" # TODO need to test this between nodes
  ];
  fsCifsDefaults = [
    "nofail"
    "user"
    "forceuid"
    "forcegid"
    "soft"
    "rw"
    "vers=3"
    "credentials=${config.age.secrets."cifs/mitch".path}"
  ];
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
  ];
  fsUserMe = [
    "uid=1000"
    "gid=100"
  ];
in
{
  imports =
    [
      ./..

      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../kernel.nix
      # ../pipewire.nix
#      ../virtualization.nix
#      ../desktop.nix
      ../zfs.nix
      ../userscompat.nix
    ];

  fileSystems = {
    "/nfs/internets" = {
        device = "s1.home.arpa:/volume1/internets";
        fsType = "nfs";
        options = [ "nofail" "soft" "rw" ];
      };
      "/nas/internets" = {
        device = "//s1.home.arpa/internets";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/media" = {
        device = "//s1.home.arpa/media";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/bitbucket" = {
        device = "//s1.home.arpa/bitbucket";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/backup" = {
        device = "//s1.home.arpa/backup";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
    };

  environment.systemPackages = [ pkgs.mullvad-vpn pkgs.mullvad ];
  networking.wireguard.enable = true;
  services.mullvad-vpn = {
    enable = true;
  };

  # wantedBy = [] to prevent it from starting even though its enabled. I want to
  # selectively enable this not always have it on.
  systemd.services."mullvad-daemon" = {
    wantedBy = pkgs.lib.mkForce [ ];
    requires = [ "nas-internets.mount" ];
  };

  systemd.services."mullvad-daemon".postStart = let
    mullvad = config.services.mullvad-vpn.package;
  in ''
    while ! ${mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
    #ID=`head -n1 blah
    ID=8824892900904832
    ${mullvad}/bin/mullvad account login "$ID"
#    ${mullvad}/bin/mullvad auto-connect set on
    ${mullvad}/bin/mullvad relay set location us
    ${mullvad}/bin/mullvad lan set allow
#    ${mullvad}/bin/mullvad tunnel ipv6 set on
  '';

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";

  # This is an intel system, do "intel" stuff to it
  services = {
    zfs.autoScrub.enable = true;
  };

  # Due to ^^^ we're setting our ip statically
  networking = {
    hostName = "nexus";
    hostId = "30d18215";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "eno1" ];
    interfaces = {
      "enp3s0f3" = {
        allowedTCPPorts = [ 22 9002 ];
        allowedUDPPorts = [ ];
      };
    };
  };
}
