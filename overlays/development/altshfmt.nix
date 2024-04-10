_self: super: {
  altshfmt = super.pkgs.callPackage ./pkgs/altshfmt.nix
    {
      inherit (super) pkgs;
    };
}
