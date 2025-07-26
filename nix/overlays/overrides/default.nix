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

  ipatool = super.ipatool.overrideAttrs (old: rec {
    version = "2.2.0";
    vendorHash = "sha256-f6mXTePiM5kZUdrYqvbN5pyNp1OGNMeJZMUJ3pvaRrc=";
    src = super.fetchFromGitHub {
      owner = "majd";
      repo = "ipatool";
      rev = "v${version}";
      hash = "sha256-z6f5PNxAH+8mS2kWjhST0LFhwTR01m7rR5O95ee+p2E=";
    };

    # If I don't do this version here seems to be from old.version somehow...
    # So cheat and just pass another -X into the build system.
    ldflags = old.ldflags ++ [
      "-X github.com/majd/ipatool/v2/cmd.version=${version}"
    ];
    latest = "curl --silent https://api.github.com/repos/majd/ipatool/tags | jq -r '.[] | .name' | grep -Ev rc | head -n 1 | tr -d v";
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
        ]
        ++ old.disabledTests;
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
