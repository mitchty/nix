self: super: {
  asm-lsp = super.asm-lsp.overrideAttrs (old: {
    meta.platforms = self.lib.platforms.unix;
    buildInputs =
      old.buildInputs
      ++ self.lib.optionals self.stdenv.isDarwin [
        self.darwin.apple_sdk.frameworks.SystemConfiguration
      ];
  });
  transcrypt = super.transcrypt.overrideAttrs (old: rec {
    patches = old.patches or [ ] ++ [
      (super.fetchpatch {
        name = "suppress-openssl-pbkdf2-warnings";
        url = "https://github.com/elasticdog/transcrypt/compare/suppress-openssl-pbkdf2-warnings.diff";
        sha256 = "sha256-wRMx/Kbkm/Xpl1aaX9jjk6xMXZf6seEg5BhkZ34WEpI=";
      })
    ];
  });
  # open-webui = super.open-webui.overrideAttrs (old: {
  #   dependencies = old.dependencies ++ [ super.python311Packages.emoji ];
  # });
}
