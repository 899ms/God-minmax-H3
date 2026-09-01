#!/usr/bin/env bash
# 导出视频最后一帧，用作下一段生成的 first_frame
# 用法: ./extract_last_frame.sh segA.mp4 segA_last.jpg
set -euo pipefail
IN="${1:?用法: $0 <输入视频> [输出图片]}"
OUT="${2:-${IN%.*}_last.jpg}"
ffmpeg -v error -sseof -0.1 -i "$IN" -frames:v 1 -q:v 1 "$OUT" -y
echo "已导出尾帧: $OUT"
