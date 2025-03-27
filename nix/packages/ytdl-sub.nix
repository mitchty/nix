{
  lib,
  pkgs,
  fetchFromGitHub,
  python3,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "ytdl-sub";
  version = "2025.03.26";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "jmbannon";
    repo = "ytdl-sub";
    rev = "refs/tags/${version}";
    hash = "sha256-gGqgTeb5yKces7c0SIGBcHQPb8DNo80zJNuaGlk+SVs=";
  };

  postPatch = ''
    substituteInPlace src/ytdl_sub/__init__.py \
        --replace '2023.10.22+bfba4f0' '${version}'
    substituteInPlace src/ytdl_sub/config/defaults.py  \
        --replace '/usr/bin/ffmpeg' '${pkgs.ffmpeg}/bin/ffmpeg' \
        --replace '/usr/bin/ffprobe' '${pkgs.ffmpeg}/bin/ffprobe'
  '';

  propagatedBuildInputs = with python3.pkgs; [
    mediafile
    mergedeep
    pyyaml
    yt-dlp
    colorama
  ];

  buildInputs = [ pkgs.ffmpeg ];

  nativeBuildInputs = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
    python3.pkgs.pythonRelaxDepsHook
  ];

  pythonRelaxDeps = true;

  pythonImportsCheck = [ "ytdl_sub" ];

  checkInputs = with python3.pkgs; [
    pytestCheckHook
    pytest
  ];

  disabledTests = [
    "test_logger_always_outputs_to_debug_file"
    "test_logger_can_be_cleaned_during_execution"
    "test_no_config_works"
  ];

  # Skip tests that use the network or need more investigation
  pytestFlagsArray = [
    "--ignore=tests/e2e"
    "--ignore=tests/integration" # TODO what about the md5sum is changing in here?
    "--ignore=tests/unit/prebuilt_presets/test_prebuilt_presets.py"
  ];

  meta = with lib; {
    mainProgram = "ytdl-sub";
    description = "Automate downloading and metadata generation with YoutubeDL";
    homepage = "https://github.com/jmbannon/ytdl-sub";
    license = licenses.gpl3Only;
  };

  latest = "curl --silent https://api.github.com/repos/jmbannon/${pname}/tags | jq -r '.[] | .name' | grep -Ev post | head -n 1";
}
