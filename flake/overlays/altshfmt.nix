{ pkgs, ... }: {
  altshfmt = pkgs.callPackage ./pkgs/altshfmt.nix {
    inherit pkgs;
    inherit (pkgs) makeWrapper fetchFromGithub;
    inherit (pkgs.stdenv) mkDerivation;
  };
}
