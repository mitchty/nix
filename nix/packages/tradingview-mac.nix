{
  system,
  lib,
  fetchurl,
  undmg,
  pkgs,
  ...
}:
if (system == "aarch64-darwin") then
  pkgs.stdenvNoCC.mkDerivation rec {
    pname = "tradingview-mac";
    version = "2.13.0";

    src = fetchurl {
      url = "https://tvd-packages.tradingview.com/stable/${version}/darwin/TradingView.dmg";
      sha256 = "sha256-/aWCfmaabybatPkbJaj1a9wPbVvYLfBEtTjJJbvD2eE=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [
      undmg
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -r *.app "$out/Applications"

      runHook postInstall
    '';

    meta = {
      description = "Tradingview app for macos";
      platforms = lib.platforms.darwin;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };

    latest = "curl --silent https://tvd-packages.tradingview.com/stable/latest/darwin/stable-mac.yml | awk '/version[:]/ {print $2}'";
  }
else
  pkgs.stdenvNoCC.mkDerivation {
    pname = "tradingview-mac";
    version = "0.0.0";
    src = ./.;
    installPhase = "mkdir -p $out/bin";
  }
