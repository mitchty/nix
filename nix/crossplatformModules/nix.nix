# Common settings for nix command itself between darwin/nixos
{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    cachix
    nix-output-monitor
  ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
    ];
    settings = {
      # https://github.com/NixOS/nix/issues/11728
      # 64MiB from 1MiB default, increase further if the buffer fills up (again,
      # with my nginx proxy cache things fill up fast even on the slower 2.5g
      # link compared to 10g ...)
      download-buffer-size = 64 * 1024 * 1024;

      # Keys I'm willing to accept as kosher
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      substituters = [
        # Ok cause I go "mobile" with some systems (mbp/wm2) sometimes its nice to
        # not have to wait for stuff to fail.
        #
        # The comment chunks are here to make it possible to comment/toggle the
        # lines inside via sed, note the automation doesn't care about
        # formatting, treefmt can fix that in post.
        #
        # Don't add #'s to these lines dumdum, it'll break the assumption that
        # the (un)comment script can nuke #'s (SCRIPT IS STUPID SIMPLE)
        # MOBILE_START
        "http://nixos.cache.home.arpa"
        # MOBILE_END
        "http://nix-community.cachix.org"
        #        "http://cachix.cache.home.arpa"
        #        "http://nix-community.cachix.cache.home.arpa"
      ];
    };
  };
}
