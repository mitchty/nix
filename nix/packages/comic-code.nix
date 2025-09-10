{
  lib,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "comic-code";
  version = "0.1.0";

  nativeBuildInputs = [ pkgs.unzip ];

  srcs = [
    ../../crypt/comic-code.zip
  ];

  sourceRoot = ".";

  # Bit of a hack but whatever more for debugging.
  buildPhase = ''
    find . -name \*.otf
    find . -name \*.ttf
  '';

  installPhase = ''
    install -dm755 $out/share/fonts/opentype/ComicCode
    find 'Comic Code Complete Family' -name \*.otf -exec mv {} $out/share/fonts/opentype/ComicCode \;
  '';

  meta = {
    description = "Fonts I paid for and abuse all over the place";
    maintainers = with lib.maintainers; [ mitchty ];
  };
}
