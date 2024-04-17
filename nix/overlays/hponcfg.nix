_self: super: {
  hponcfg = super.pkgs.callPackage ../pkgs/hponcfg.nix {
    fetchurl = super.pkgs.fetchurl;
    rpmextract = super.pkgs.rpmextract;
    openssl = super.pkgs.openssl;
    busybox = super.pkgs.busybox;
    autoPatchelfHook = super.pkgs.autoPatchelfHook;
    makeWrapper = super.pkgs.makeWrapper;
  };
}
