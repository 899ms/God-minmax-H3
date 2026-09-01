#!/usr/bin/env bash
# 抽出音轨，用作下一段生成的 reference_audio（对白片必做）
# 用法: ./extract_audio.sh segA.mp4 segA_audio.mp3
set -euo pipefail
IN="${1:?用法: $0 <输入视频> [输出音频]}"
OUT="${2:-${IN%.*}_audio.mp3}"
ffmpeg -v error -i "$IN" -vn -acodec libmp3lame -q:a 2 "$OUT" -y
echo "已导出音轨: $OUT"
