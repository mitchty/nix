{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
}:
let
  owner = "hagezi";
  repo = "dns-blocklists";
in
stdenv.mkDerivation rec {
  pname = "dns-blocklists";
  version = "32025.148.28069";

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "${version}";
    sha256 = "sha256-+Q9RA22ZCW9AmkGRrMvW0OPILrGtqNgvAQoIFcufVm0=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -dm755 $out
    install -m644 dnsmasq/pro.plus.txt $out/dnsmasq-blocklist
  '';

  meta = {
    description = "Dnsmasq blacklist";
    homepage = "https://github.com/${owner}/${repo}";
  };

  latest = "curl --silent https://api.github.com/repos/${owner}/${repo}/tags | jq -r '.[] | .name' | head -n 1";
}
