{ lib, ... }:
{
  # Setup a cifs mount to the synology.
  mkCifsMount =
    {
      mountpoint,
      share,
      creds,
      uid ? 1000, # "mitch" uid
      gid ? 100, # "users" gid
      prefix ? "/nas",
      server ? "s1.home.arpa",
    }:
    {
      "${prefix}/${mountpoint}" = {
        device = "//${server}/${share}";
        fsType = "cifs";
        options = [
          # Common user options
          "user" # NB keep this above exec or you can't run scripts off this mount point
          "mfsymlinks"
          "exec"
          "nofail"
          "forceuid"
          "forcegid"
          "soft"
          "rw"
          "vers=3"
          "credentials=${creds}"
          # Automount related options
          "x-systemd.automount"
          "x-systemd.idle-timeout=300"
          "x-systemd.mount-timeout=60s"
          "nofail"
          # perf...ish options
          "bsize=8388608"
          "rsize=131072"
          #"cache=loose" # TODO need to test this between nodes
          # Who we're mounting this for
          "uid=${uid}"
          "gid=${gid}"
        ];
      };
    };
}
