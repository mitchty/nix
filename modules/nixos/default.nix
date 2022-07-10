{ ... }:

# TODO: Should probably break this out into a library function/library in general... Future me deal with it.
let
  # TODO: bother with this?
  cifsMount = remotePath: {
    device = "//10.10.10.191/${remotePath}";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=10s,file_mode=0660,dir_mode=0770,gid=1,nounix";
      in
      [ "${automount_opts},credentials=/run/agenix/dfs1.home.arpa,vers=1.0" ];
  };
in
{
  # TODO: Migrate configuration/setup out of hosts/*.nix to a module setup
  imports = [
    ./intel.nix
    ./nas.nix
    ./lowmem.nix
    ./gui.nix
    ./router.nix
    ./promtail.nix
  ];
}
