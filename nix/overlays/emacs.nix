self: super:
let
  # These are the nixpkgs packages that I need to make sure are included with
  # emacs for editing rando source.
  #
  # The idea is we use wrapProgram to setup PATH for emacs itself versus make
  # sure that these are installed within the $HOME or system packages.
  editorPackages = with super.pkgs; [
    (pkgs.hiPrio clang)
    altshfmt
    asm-lsp
    clang-tools
    coreutils
    curl
    deadnix
    emacs-lsp-booster
    gcc11
    git-lfs
    gitFull
    gnumake
    ispell
    nil
    nixfmt-rfc-style
    nodePackages.bash-language-server
    python3Full
    rage
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
    rust-analyzer-nightly
  ];

in
# TODO Hack to make the "version" of this crap take on the mtime of the file
# itself. Note, not working entirely for some reason grrr future me problem.
#   datever =
#     super.pkgs.runCommand "emacs-overlay-file-mtime"
#       "date -r ${./default.nix} +%Y.%m.%d.%H.%M.%S > $out";
rec {
  # This is my complicated af overlay for emacs
  #
  # The overall situation is I've hit issues with using org mode init files with the overlay.
  #
  # So this overlay defines a set of derivations that do:
  # - "compiles/tangles" the org mode file to .el directly
  # - uses ^^^^ to ensure the patched emacs I have can run in case I eff up missing a ) somewhere. Not that that eeeever happens
  # - tests out that tree-sitter/modes/etc et al work with the entire config by batch loading the tangled .el file itself with itself to prove out everything with modes works overall in case for some reason tree sitter loading a dylib segfaults for god knows why (never figured out what was causing it just managed to get this all to work again somehow so since this all works with a test I'm OK with that)
  #

  # Shared config overrideattr'd in with other derivations not really useful on
  # its own, well not intended to be by me at least.
  emacsShared = super.emacs30.override {
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

  # https://github.com/nix-community/emacs-overlay/issues/411
  #
  # Fix is only in nixpkgs-unstable
  #
  # TODO Figure out a way to not have to hack in the patch override for emacs-org
  override2405OrgHack = final: prev: {
    org = prev.org.overrideAttrs (old: {
      patches = [ ];
    });
    # emacsWithPackages = epkgs: with epkgs; [
    #   (treesit-grammars.with-all-grammars)
    #   # (treesit-grammars.with-grammars (p: [
    #   #   p.tree-sitter-bash
    #   #   p.tree-sitter-c
    #   #   p.tree-sitter-dockerfile
    #   #   p.tree-sitter-elisp
    #   #   p.tree-sitter-glsl
    #   #   p.tree-sitter-haskell
    #   #   p.tree-sitter-html
    #   #   p.tree-sitter-http
    #   #   p.tree-sitter-json
    #   #   p.tree-sitter-latex
    #   #   p.tree-sitter-
    #   # ]))
    # ];
  };

  # Only used to validate the overlay
  myEmacsPrime = super.emacsWithPackagesFromUsePackage {
    #      override = override2405OrgHack;
    config = ../../static/emacs/init.org;
    package = emacsPatched;
  };

  # Convert org to .el so init.el can stay in the nix store.
  myInitEl = super.stdenv.mkDerivation rec {
    pname = "myinitel";
    # version = builtins.readFile super.pkgs.runCommand "emacs-overlay-file-mtime"
    #   "date -r ${./default.nix} +%Y.%m.%d.%H.%M.%S > $out";
    version = "0.0.0";
    buildInputs = [
      self.myEmacsPrime
    ];
    src = ../../static/emacs;

    # abuse this derivation to munge org->el so we can use that for default init file
    # and then also use that to batch load it.
    buildPhase = ''
      emacs -Q --batch --eval "
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
  myTestedEmacsConfig = super.stdenv.mkDerivation rec {
    pname = "mytestedemacsconfig";

    # version = builtins.readFile wtfMtime;
    version = "0.0.0";
    # TODOhow in the hell does this work in nix repl but not in a derivation? I
    # just want to have the package date come from build time...
    # version = builtins.readFile (super.pkgs.runCommand "init-el-mtime" { } "${super.pkgs.coreutils}/bin/date -r ./. +%Y.%m.%d.%H.%M.%S > $out");
    buildInputs = [
      self.myEmacsPrime
    ];
    src = ../../static/emacs;

    # For emacs 28.?+ --init-directory simplifies this a skosh to my prior
    # --load hacks.
    # https://stackoverflow.com/questions/71146526/how-to-start-emacs-with-specific-user-init-file-and-user-emacs-directory
    buildPhase = ''
      export HOME=$TMPDIR
      echo emacs batch load to make sure init.el is parseable >&2
      emacs -nw --batch --debug-init --init-directory ${self.myInitEl}
    '';

    installPhase = ''
      install -dm755 $out
      install -m644 ${self.myInitEl}/init.el $out/init.el
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
    config = "${self.myTestedEmacsConfig}/init.el";

    # If for some reason I need to override an emacs package directly
    #      override = epkgs: epkgs // {
    #        inherit eglot-booster;
    # ligature = epkgs.trivialBuild { pname = "ligature"; src = sources.emacs-ligature; };
    #     };
  };

  # use symlinkJoin instead of PATH for pkgs knowledge
  wrappedEmacs = super.pkgs.symlinkJoin {
    name = "mt-emacs";
    meta.mainProgram = "emacs";
    paths = [ myEmacs ];
    nativeBuildInputs = [ super.pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/emacs --prefix PATH : "${super.lib.makeBinPath editorPackages}"
    '';
  };
}
