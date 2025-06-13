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
  version = "37512025.164.40721";

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "${version}";
    sha256 = "sha256-WXfqNeJdFQz2KFkg0Hm6NtDDya2EALNTWIki9GKkSaQ=";
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
