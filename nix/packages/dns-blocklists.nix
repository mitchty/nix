{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "dns-blocklists";
  version = "32025.110.13251";

  src = pkgs.fetchFromGitHub {
    owner = "hagezi";
    repo = "dns-blocklists";
    rev = "${version}";
    sha256 = "sha256-7ICQRTMXqT7vak1laIgov7zoSnq5xZCvsJDXit8MGF8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -dm755 $out
    install -m644 dnsmasq/pro.plus.txt $out/dnsmasq-blocklist
  '';

  meta = {
    description = "Dnsmasq blacklist";
    maintainers = with lib.maintainers; [ mitchty ];
    homepage = "https://github.com/hagezi/dns-blocklists";
  };
}
