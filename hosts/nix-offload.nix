# Don't offload on every host or at least make it configurable per node
{ lib, inputs, ... }: {
  programs.ssh.extraConfig = ''
    Host offload
      HostName srv.home.arpa
      User root
      IdentitiesOnly yes
      IdentityFile /home/mitch/.ssh/id_rsa
    Host offload-coffee-shoppe
      HostName srv.home.arpa
      ProxyJump mitch@home.mitchty.net
      User root
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
