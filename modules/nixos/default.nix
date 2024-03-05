_:

{
  # imports = [ mylib.nixFiles ./. ];
  imports = [
    ./cluster.nix
    ./media.nix
    ./grafana.nix
    ./gui.nix
    ./qemu.nix
    ./gaming.nix
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
    ../shared/default.nix
  ];
}
