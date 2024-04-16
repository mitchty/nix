# The stupid warnings suck so add a patch to kill em.
_self: super: {
  transcrypt = super.transcrypt.overrideAttrs (old: rec {
    patches = old.patches or [ ] ++ [
      (super.fetchpatch {
        name = "suppress-openssl-pbkdf2-warnings";
        url = "https://github.com/elasticdog/transcrypt/compare/suppress-openssl-pbkdf2-warnings.diff";
        sha256 = "sha256-wRMx/Kbkm/Xpl1aaX9jjk6xMXZf6seEg5BhkZ34WEpI=";
      })
    ];
  });
}
