# Don't offload on every host or at least make it configurable per node
#
# I should have all my nix config be a module, then I can append the home
# offload via the outside world be an optional thing for only the mobile
# clients. Which really isn't more than 1 really right now.
{ lib, inputs, ... }: {
  programs.ssh.extraConfig = ''
    Host offload
      HostName rtx.home.arpa
      User root
      IdentitiesOnly yes
      IdentityFile /home/mitch/.ssh/id_rsa
    Host home
      HostName home.mitchty.net
      User mitch
      IdentitiesOnly yes
      IdentityFile /home/mitch/.ssh/id_rsa
    Host offload-via-home
      HostName rtx.home.arpa
      User root
      ProxyJump home
      IdentitiesOnly yes
      IdentityFile /home/mitch/.ssh/id_rsa
  '';

  # Prefer the non proxyjump hostname
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "offload";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 4;
        speedFactor = 2; # default is one, higher is faster
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      }
      {
        hostName = "offload-coffee-shoppe";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 4;
        # no speedFactor for this one we want not to prefer this path
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      }
    ];
  };
}
