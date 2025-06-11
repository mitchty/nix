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

  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      # I keep getting errno 3 Temporary failure in name resolution on this for some reason now.
      #
      # Who does a POST to a webpage in a unit test though? Why is this data not
      # in the repo ungh ai tooling is as bad as the llm responses they give.
      langchain-community = pyprev.langchain-community.overridePythonAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
        dontCheck = true;
        disabledTests = [
          "test_llm_caching"
          "test_llm_caching_async"
        ] ++ old.disabledTests;
      });
      open-webui = pyprev.open-webui.overridePythonAttrs (old: {
        dependencies =
          old.dependencies
          ++ (with super.pkgs.python3Packages; [
            emoji
            iso-639
            langdetect
          ]);
      });
    })
  ];
}
