{ stdenv
, lib
, pkgs
}:
with pkgs; stdenv.mkDerivation rec {
  name = "obs-studio";
  uname = "obsproject";
  aname = "OBS";
  version = "28.0.1";

  sourceRoot = ".";
  phases = [ "installPhase" ];
  installPhase = ''
    install -dm755 "$out/Applications"
    VOLUME=`/usr/bin/hdiutil attach $src | grep Volumes | awk '{print $3}'`
    cp -rf $VOLUME/${aname}.app $out/Applications/${aname}.app
    /usr/bin/hdiutil detach $VOLUME
  '';

  src = fetchurl {
    name = "${aname}.dmg";
    # As of obs 28.0.0 this disk image is now APFS and not HFS, so undmg no worky
    url = "https://github.com/${uname}/${name}/releases/download/${version}/obs-studio-${version}-macos-x86_64.dmg";
    sha256 = "sha256-JG4bF0rz9hUT5OAE6UijJRSQkbUWW3AFORVw9tM07j4=";
  };
}
