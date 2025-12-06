{
  lib,
  pkgs,
}:
let
  owner = "bodaay";
  repo = "HuggingFaceModelDownloader";
in
pkgs.buildGoModule rec {
  pname = "hfdownloader";
  version = "2.0.0";
  vendorHash = "sha256-3xSLD0vEKedk/7LCxmKjHGuBvE9fd78aUoXYzmkDB1k=";

  src = pkgs.fetchFromGitHub {
    inherit owner repo;
    rev = "${version}";
    hash = "sha256-gVCsUoUMYNxp99q1XED3+i4C0gdplDeVs+tZrgnzH7M=";
  };

  postInstall = ''
    mv $out/bin/HuggingFaceModelDownloader $out/bin/hfdownloader
  '';

  meta = with lib; {
    description = "The HuggingFace Model Downloader is a utility tool for downloading models and datasets from the HuggingFace website";
    homepage = "https://github.com/bodaay/HuggingFaceModelDownloader";
    license = licenses.asl20;
    maintainers = with lib.maintainers; [ mitchty ];
  };

  latest = "curl --silent https://api.github.com/repos/${owner}/${repo}/tags | jq -r '.[] | .name' | grep -Ev post | head -n 1";
}
