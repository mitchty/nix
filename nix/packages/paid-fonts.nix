{
  lib,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "paid-fonts";
  version = "0.1.0";

  nativeBuildInputs = [ pkgs.unzip ];

  srcs = [
    ../../crypt/comic-code.zip
    ../../crypt/pragmata-pro.zip
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
    install -dm755 $out/share/fonts/truetype/PragmataPro
    find 'Pragmata Pro Family' -name \*.ttf -exec mv {} $out/share/fonts/truetype/PragmataPro \;
  '';

  meta = {
    description = "Fonts I paid for and abuse all over the place";
    maintainers = with lib.maintainers; [ mitchty ];
  };
}
