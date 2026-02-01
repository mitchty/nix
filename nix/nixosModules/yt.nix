{ pkgs, lib, ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      bgutil-ytdlp-pot-provider = {
        image = "docker.io/brainicism/bgutil-ytdlp-pot-provider:1.2.2";
        autoStart = true;
        ports = [ "127.0.0.1:4416:4416" ];
      };
    };
  };
}
