{
  lib,
  pkgs,
}:
let
  owner = "antirez";
  repo = "gguf-tools";
  name = "${repo}-${version}";
  version = "a3257ff3";
in
pkgs.stdenv.mkDerivation {
  inherit name version;

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "a3257ff3cb8aed8b60ba3243c70b85a17491d7d6";
    sha256 = "1dgm1l194blgcbg1ma1lmzprydfgbbkv5bvp1mpdg6ysc2g6i8d4";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp -p gguf-tools $out/bin
  '';

  meta = {
    homepage = "https://github.com/antirez/gguf-tools";
    description = "This is a work in progress library to manipulate GGUF files";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mitchty ];
  };

  latest = "curl --silent -H 'Accept: application/vnd.github.VERSION.sha' https://api.github.com/repos/${owner}/${repo}/commits/main | cut -c1-8";
}
