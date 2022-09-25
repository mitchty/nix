{ stdenv
, lib
, pkgs
}:
with pkgs; stdenv.mkDerivation rec {
  name = "stretchly";
  uname = "hovancik";
  aname = "Stretchly";
  version = "1.11.0";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    install -dm755 "$out/Applications"
    cp -r ${aname}.app "$out/Applications/${aname}.app"
  '';

  src = fetchurl {
    # https://github.com/hovancik/stretchly/releases/download/v1.10.0/Stretchly-1.10.0.dmg
    url = "https://github.com/${uname}/${name}/releases/download/v${version}/${aname}-${version}.dmg";
    sha256 = "sha256-Bq/Os5jrR52SITM/bxxSGIRFZTQ+ZT3ZoBuHTAzRO7c=";
  };
}
