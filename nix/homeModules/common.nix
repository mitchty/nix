{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  nix = {
    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };

  home = {
    packages = with pkgs; [
      #bind.dnsutils
      curl
      dasel
      diffoscopeMinimal
      difftastic
      dust
      file
      gist
      gron
      hwatch
      hyperfine
      ipcalc
      ipinfo
      jid
      jless
      less
      libqalculate
      mapcidr
      moreutils
      passh # Use over sshpass generally ref: https://github.com/clarkwang/passh?tab=readme-ov-file#examples for times its not a great option over sshpass
      sshpass
      pv
      rclone
      ripgrep
      rq
      scripts # TODO: should pull this package apart and make scripts-macos scripts-blah future mitch problem
      sqlite
      tldr
      tree
      wget
      vim # cause well still comes in handy over ssh at times.
    ];
  };

  home = {
    file = {
      ".config/direnv/lib/mycrap.sh".source = ../../src/lib.sh;
      ".config/btop/btop.conf".source = ../../static/btop/btop.conf;
      ".canary".text = "ok";
      ".ssh/config".source = ../../static/home/sshconfig;
    };
  };

  programs.direnv = {
    enable = true;
    stdlib = lib.readFile ../../static/home/direnvrc;
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # TODO: need to brain how to tack this into my direnvrc setup
  #   # xdg.configFile."direnv/direnvrc".text =
  #   #   "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

  #   programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
  #     man.generateCaches = true;
  #   };
}
