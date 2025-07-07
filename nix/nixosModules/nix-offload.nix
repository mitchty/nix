# Don't offload on every host or at least make it configurable per node
#
# I should have all my nix config be a module, then I can append the home
# offload via the outside world be an optional thing for only the mobile
# clients. Which really isn't more than 1 really right now.
{ lib, inputs, ... }:
{
  programs.ssh.extraConfig = ''
    Host offload
      HostName rtx.home.arpa
      User root
      IdentitiesOnly yes
      IdentityFile /home/mitch/.ssh/id_ed25519
  '';

  # Prefer the non proxyjump hostname
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "offload";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        maxJobs = 4;
        speedFactor = 2; # default is one, higher is faster
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };
}
