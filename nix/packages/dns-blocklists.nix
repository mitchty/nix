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
  version = "32025.139.71246";

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "${version}";
    sha256 = "sha256-j7GodNu5XvAmofP5L0WbuL/TSWK5V03V8LHJ7Iqd38o=";
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
