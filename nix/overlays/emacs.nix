self: super:
let
  enableFullBuild = import ../../hacks/flake-check.nix;
in
if enableFullBuild then
  # Full complex emacs build - only evaluate when enableFullBuild is true
  let
    # These are the nixpkgs packages that I need to make sure are included with
    # emacs for editing rando source.
    #
    # The idea is we use wrapProgram to setup PATH for emacs itself versus make
    # sure that these are installed within the $HOME or system packages.
    editorPackages =
      with super.pkgs;
      super.lib.optionals enableFullBuild [ eca ]
      ++ [
        (pkgs.hiPrio clang)
        altshfmt
        asm-lsp
        brave
        clang-tools
        coreutils
        curl
        deadnix
        ditaa
        emacs-lsp-booster
        gcc11
        git-lfs
        gitFull
        gnumake
        gnumake
        ispell
        mermaid-cli
        nil
        nixfmt-rfc-style
        nodePackages.bash-language-server
        plantuml
        python3Full
        rage
        rust-analyzer-nightly
        shellcheck
        shellspec
        shfmt
        yaml-language-server

        # fenix nixpkgs overlay stuff
        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ])
      ];

    # Shared config overrideattr'd in with other derivations not really useful on
    # its own, well not intended to be by me at least.
    emacsShared = self.emacs30.override {
      withSQLite3 = true;
      withWebP = true;
      withImageMagick = true;
      withTreeSitter = true;
    };

    # Patched emacs-overlay for each platform I care about e.g. linux/macos
    emacsPatched =
      # I yeet a lot of patches at the nextstep darwin build of emacs cause the
      # defaults kinda ass so we want to improve it slightly.
      if super.hostPlatform.isDarwin then
        emacsShared.overrideAttrs (old: {
          # bit old mostly off this https://github.com/NixOS/nixpkgs/issues/12863 assume its been fixed but should find out.
          # TODO: still needed?
          preConfigure = ''
            sed -i -e 's/headerpad_extra=1000/headerpad_extra=2000/' configure.ac
            autoreconf
          '';
          configureFlags = old.configureFlags ++ [
            "--disable-build-details"
            "--with-modules"
            "--with-native-comp"
            "--with-natural-title-bar"
          ];

          patches = (old.patches or [ ]) ++ [
            # Fixes incorrect window role in macos
            (super.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
              sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
            })
            # TESTING: Add setting to enable rounded window with no decoration (still have to alter default-frame-alist)
            (super.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/round-undecorated-frame.patch";
              sha256 = "uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
            })
            # Make Emacs aware of OS-level light/dark mode
            # https://github.com/d12frosted/homebrew-emacs-plus#system-appearance-change
            (super.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/system-appearance.patch";
              sha256 = "sha256-3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
            })
          ];
        })
      # basically everything else, for now this means linux
      else
        (emacsShared.override {
          withX = true;
          withGTK3 = true;
          withXinput2 = true;
        }).overrideAttrs
          (_: {
            configureFlags = [
              "--disable-build-details"
              "--with-modules"
              "--with-x-toolkit=gtk3"
              "--with-xft"
              "--with-cairo"
              "--with-xaw3d"
              "--with-native-compilation"
              "--with-imagemagick"
              "--with-xinput2"
            ];
          });

    # Only used to validate the overlay
    myEmacsPrime = super.emacsWithPackagesFromUsePackage {
      #      override = override2405OrgHack;
      config = ../../static/emacs/init.org;
      package = emacsPatched;
    };

    # Convert org to .el so init.el can stay in the nix store.
    myInitEl = super.stdenv.mkDerivation {
      pname = "myinitel";
      # version = builtins.readFile super.pkgs.runCommand "emacs-overlay-file-mtime"
      #   "date -r ${./default.nix} +%Y.%m.%d.%H.%M.%S > $out";
      version = "0.0.0";
      buildInputs = [
        myEmacsPrime
      ];
      src = ../../static/emacs;

      # abuse this derivation to munge org->el so we can use that for default init file
      # and then also use that to batch load it.
      buildPhase = ''
        ${super.pkgs.emacs}/bin/emacs -Q --batch --eval "
            (progn
              (require 'ob-tangle)
              (dolist (file command-line-args-left)
                (with-current-buffer (find-file-noselect file)
                  (org-babel-tangle))))
          " init.org
      '';

      installPhase = ''
        install -dm755 $out
        install -m644 init.org $out/init.org
        install -m644 init.el $out/init.el
      '';
    };

    # Use the generated init.el to test out the configuration.
    myTestedEmacsConfig = super.stdenv.mkDerivation {
      pname = "mytestedemacsconfig";

      # version = builtins.readFile wtfMtime;
      version = "0.0.0";
      # TODOhow in the hell does this work in nix repl but not in a derivation? I
      # just want to have the package date come from build time...
      # version = builtins.readFile (super.pkgs.runCommand "init-el-mtime" { } "${super.pkgs.coreutils}/bin/date -r ./. +%Y.%m.%d.%H.%M.%S > $out");
      buildInputs = [
        myEmacsPrime
      ];
      src = ../../static/emacs;

      # For emacs 28.?+ --init-directory simplifies this a skosh to my prior
      # --load hacks.
      # https://stackoverflow.com/questions/71146526/how-to-start-emacs-with-specific-user-init-file-and-user-emacs-directory
      buildPhase = ''
        export HOME=$TMPDIR
        echo emacs batch load to make sure init.el is parseable >&2
        ${super.pkgs.emacs}/bin/emacs -nw --batch --debug-init --init-directory ${myInitEl}
      '';

      installPhase = ''
        install -dm755 $out
        install -m644 ${myInitEl}/init.el $out/init.el
      '';
    };

    # me emacs all wrapped up in one spiel
    # TODO make a wrapper "emacs" that wraps the entire config + package
    # dependencies so that I don't need to include things in the emacs config into
    # my regular config.
    #
    # TODO also include any setup outside of init.org here like treesitter
    # grammars etc...
    myEmacs = super.emacsWithPackagesFromUsePackage {
      #      override = override2405OrgHack;
      package = emacsPatched;
      defaultInitFile = true;
      config = "${myTestedEmacsConfig}/init.el";

      # override = epkgs: epkgs // { inherit ecaepkg; };
      # If for some reason I need to override an emacs package directly
      # override =
      #   epkgs:
      #   epkgs
      #   // {
      #     inherit ecaepkg;
      #     #    ligature = epkgs.trivialBuild { pname = "ligature"; src = sources.emacs-ligature; };
      #   };
    };

    # use symlinkJoin instead of PATH for pkgs knowledge
    wrappedEmacs = super.pkgs.symlinkJoin {
      name = "mt-emacs";
      meta.mainProgram = "emacs";
      paths = [ myEmacs ];
      nativeBuildInputs = [ super.pkgs.makeWrapper ];
      # puppeteer bs is for mermaid, so lame
      postBuild = ''
        wrapProgram $out/bin/emacs --prefix PATH : "${super.lib.makeBinPath editorPackages}" --set PUPPETEER_EXECUTABLE_PATH ${super.pkgs.brave}/bin/brave
      '';
    };
  in
  # Return the full overlay with custom emacs
  {
    # Only export wrappedEmacs which is what's actually used
    # The intermediate derivations (emacsShared, emacsPatched, etc.) are kept internal to avoid
    # cross-platform evaluation issues during nix flake check
    inherit wrappedEmacs;

    # Also export these for debugging/development if needed
    # inherit emacsShared emacsPatched myEmacsPrime myInitEl myTestedEmacsConfig myEmacs;
  }
else
  # Simple fallback for flake check - don't evaluate any of the complex build
  {
    wrappedEmacs = super.emacs;
  }
