{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports = with inputs.self.homeModules; [ emacs ];

  options.nixGL.package = mkOption {
    type = types.package;
    default = pkgs.nixgl.nixGLMesa;
  };

  # This is all the junk for my normal username I always want setup.
  #
  # Gooey stuff/macos/etc... go elsewhere.
  #
  # TODO: Future mitch, a lot of these packages are actually for emacs ultimately.
  #
  # Get the wrapper package to include that junk in the emacs derivation itself
  # and not pollute the user namespace with crap.
  #
  # I can probably ditch most of this for direnv.
  config = {
    home = {
      packages = with pkgs; [
        (nixgl.nixGLCommon config.nixGL.package)
        asm-lsp
        bind.dnsutils
        bonnie
        coreutils
        curl
        dasel
        dateutils
        diffoscopeMinimal
        difftastic
        du-dust
        entr
        fd
        file
        fio
        gist
        git
        git-absorb
        git-extras
        git-lfs
        git-quick-stats
        git-recent
        git-sizer
        git-vendor
        gitFull
        glibcInfo
        gnumake
        gnutar
        graphviz
        gron
        htop
        hwatch
        hyperfine
        iftop
        ipcalc
        ipinfo
        jid
        jless
        kopia
        less
        libqalculate
        man-pages
        man-pages-posix
        mapcidr
        mercurial
        mermaid-cli
        moreutils
        nvd
        openssl
        p7zip
        passh
        pbzip2
        pigz
        podman
        procps
        pssh
        pv
        rage
        rclone
        ripgrep
        rq
        s3cmd
        shellcheck
        shellspec
        shfmt
        sipcalc
        sqlite
        sshpass
        strace
        tldr
        tmuxp
        transcrypt
        tree
        unzip
        vim
        wget
        xq
        xz
        zstd
      ];
    };

    fonts.fontconfig.enable = true;

    xdg.configFile."direnv/direnvrc".text = ''
      source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
      source ./../static/home/direnvrc
    '';

    # programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
    #   man.generateCaches = true;
    #   git = {
    #     userName = "Archit Gupta";
    #     userEmail = "archit@accelbread.com";
    #     extraConfig = {
    #       pull.ff = "only";
    #       clone.filterSubmodules = true;
    #       user.useConfigOnly = true;
    #       advice.detachedHead = false;
    #       diff = {
    #         algorithm = "histogram";
    #         submodule = "log";
    #         colorMoved = "zebra";
    #       };
    #       merge.conflictStyle = "diff3";
    #       status.submoduleSummary = true;
    #       init = {
    #         defaultBranch = "master";
    #         templateDir = "${../../dotfiles/git-template}";
    #       };
    #       remote.pushDefault = "origin";
    #       checkout.workers = 0;
    #       commit.verbose = true;
    #       branch.sort = "-committerdate";
    #       tag.sort = "version:refname";
    #       "diff \"lisp\"".xfuncname = "^(\\(def\\S+\\s+\\S+)";
    #     };
    #     attributes = [ "*.el diff=lisp" ];
    #     ignores = [ ".envrc" ];
    #   };
    # less.keys = ''
    #   #env
    #   LESS = -i -R
    # '';
    #};
  };
}
