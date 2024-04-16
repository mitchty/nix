_self: super: rec {
  # Note these are encrypted on disk in git as they are paid so don't look at
  # this to work for you unless you buy them too, pay the font designers to do
  # their thing.
  comic-code = super.stdenv.mkDerivation rec {
    pname = "comiccode";
    version = "0.0.0";
    nativeBuildInputs = [ super.unzip ];
    src = ../../secrets/crypt/comic-code.zip;
    sourceRoot = ".";
    buildPhase = ''
      find -name \*.otf
    '';
    installPhase = ''
      install -dm755 $out/share/fonts/opentype/ComicCode
      find -name \*.otf -exec mv {} $out/share/fonts/opentype/ComicCode \;
    '';
  };

  pragmata-pro = super.stdenv.mkDerivation rec {
    pname = "pragmatapro";
    version = "0.0.0";
    nativeBuildInputs = [ super.unzip ];
    src = ../../secrets/crypt/pragmata-pro.zip;
    sourceRoot = ".";
    buildPhase = ''
      find -name \*.ttf
    '';
    installPhase = ''
      install -dm755 $out/share/fonts/truetype/PragmataPro
      find -name \*.ttf -exec mv {} $out/share/fonts/truetype/PragmataPro \;
    '';
  };
}
