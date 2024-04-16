_self: super: {
  hponcfg = super.pkgs.callPackage ../pkgs/hponcfg.nix
    {
      inherit (super) pkgs;
    };
}
