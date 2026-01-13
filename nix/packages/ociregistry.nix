{
  lib,
  pkgs,
}:
let
  owner = "aceeric";
  repo = "ociregistry";
in
pkgs.buildGoModule rec {
  pname = "ociregistry";
  version = "1.11.1"; # TODO: better way to get this?
  vendorHash = "sha256-YBFm7eWAUvRH3sxD8t65fSmH2WWMukEoJXlG0EvVUHo=";

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "${version}";
    hash = "sha256-DzOTkh4fTfb+CpyS2hjWOogw29oDqPE7Rh0uwAMwDYU=";
  };

  patches = [ ./ociregistry-bind-addr.patch ];

  subPackages = [ "cmd" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.buildVer=${version}"
    "-X main.buildDtm=1970-01-01T00:00:00Z"
  ];

  # TODO: tests should probably be figured out I was lay zee
  doCheck = false;

  postInstall = ''
    mv $out/bin/cmd $out/bin/ociregistry
  '';

  meta = with lib; {
    description = "Pull-only, pull-through, caching OCI distribution server";
    homepage = "https://github.com/aceeric/ociregistry";
    license = licenses.asl20;
    maintainers = with lib.maintainers; [ mitchty ];
    mainProgram = "ociregistry";
  };

  # TODO: not sure how I want to tackle this yet
  latest = "curl --silent https://api.github.com/repos/${owner}/${repo}/tags | jq -r '.[].name' | head -n 1";
}
