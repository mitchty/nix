#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: abuse abominable intelligence to extract and summarize a video
# cause videos are long and life is short. Abuses ollama directly cause why not
# its a script.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set -eu

whisper="${1?need the whisperfile}"
shift
video="${1?need a video file too}"
shift
model="${1:-llama3.1:latest}"

vidname=$(basename "${video}")

base=$(TMPDIR=/tmp mktemp -d XXXXXXXX -t)

trap 'rm -fr ${base}' EXIT TERM INT QUIT

cd "${base}" || exit 126

if [ ! -f "${whisper}" ]; then
  curl -sLO https://huggingface.co/Mozilla/whisperfile/resolve/main/whisper-tiny.en.llamafile
  install -m755 whisper-tiny.en.llamafile "${whisper}"
fi

# Extract the audio track and convert to mp3 192k for whisper to use, doesn't
# seem to work with aac audio.
ffmpeg -i "${video}" -vn -ar 44100 -ac 2 -b:a 192k output.mp3 > /dev/null 2>&1

${whisper} -pc -f output.mp3 2> /dev/null > whisper.out

sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' < whisper.out | awk '/-->/ {gsub(/\\/, "", $0);$1=$2=$3=""; print}' | grep -Ev '\[(MUSIC|SOUND|BLANK_AUDIO)\]' | sed -e 's/^   //' > whisper.filtered

# if [ -z ${TRANSCRIPT} ]; then
#   cat whisper.filtered
# fi

{
  printf "summarize this transcript, only output the summary text don't add any other hints or helpful output about future interaction:\n"
  cat whisper.filtered
  # strip the <think> nonsense from reasoning models
} | ollama run "${model}" | sed -e '/<think>/,/<\/think>/d'

# Iff needed uncomment as necessary.
install -m444 whisper.out "/tmp/${vidname}.out"
install -m444 whisper.filtered "/tmp/${vidname}.filtered"
