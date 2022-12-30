{ ... }:

let
  mylib = import ../../lib;
  # TODO: bother with this?
  # cifsMount = remotePath: {
  #   device = "//10.10.10.191/${remotePath}";
  #   fsType = "cifs";
  #   options =
  #     let
  #       automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=10s,file_mode=0660,dir_mode=0770,gid=1,nounix";
  #     in
  #     [ "${automount_opts},credentials=/run/agenix/dfs1.home.arpa,vers=1.0" ];
  # };
in
{
  # imports = [ mylib.nixFiles ./. ];
  imports = [
    ./cluster.nix
    ./grafana.nix
    ./gui.nix
    ./highmem.nix
    ./intel.nix
    ./loki.nix
    ./lowmem.nix
    ./mosh.nix
    ./nas.nix
    ./nix-cache.nix
    ./node-exporter.nix
    ./prometheus.nix
    ./promtail.nix
    ./router.nix
    ./syncthing.nix
  ];
}
