#!/usr/bin/env bash
# 拼接多段 H3 片段，做音频交叉淡化，并锁死目标时长
# 用法: ./stitch.sh <目标秒数> <输出文件> <片段1> <片段2> [片段3 ...]
# 例:   ./stitch.sh 29 final.mp4 segA.mp4 segB.mp4
set -euo pipefail

TARGET="${1:?用法: $0 <目标秒数> <输出> <片段...>}"
OUT="${2:?用法: $0 <目标秒数> <输出> <片段...>}"
shift 2
SEGS=("$@")
N=${#SEGS[@]}
[ "$N" -ge 2 ] || { echo "至少需要两个片段"; exit 1; }

INPUTS=(); MAPS=""
for f in "${SEGS[@]}"; do
  [ -f "$f" ] || { echo "找不到文件: $f"; exit 1; }
  INPUTS+=(-i "$f")
done
for ((i=0; i<N; i++)); do MAPS+="[${i}:v][${i}:a]"; done

FADE_OUT=$(awk -v t="$TARGET" 'BEGIN{printf "%.2f", t-0.2}')
TMP="$(mktemp -u).mp4"

echo "→ 拼接 $N 段并做交叉淡化..."
ffmpeg -v error "${INPUTS[@]}" -filter_complex \
  "${MAPS}concat=n=${N}:v=1:a=1[v][a];[a]afade=t=in:st=0:d=0.2,afade=t=out:st=${FADE_OUT}:d=0.2[ao]" \
  -map "[v]" -map "[ao]" -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p \
  -c:a aac -b:a 192k "$TMP" -y

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP")
DIFF=$(awk -v d="$DUR" -v t="$TARGET" 'BEGIN{printf "%.3f", t-d}')
echo "→ 拼接后 ${DUR}s，目标 ${TARGET}s，差 ${DIFF}s"

if awk -v x="$DIFF" 'BEGIN{exit !(x < -0.01)}'; then
  echo "→ 超长，裁切到 ${TARGET}s"
  # 必须重编码：-c copy 只能在关键帧上切，时长会差出零点几秒
  ffmpeg -v error -i "$TMP" -t "$TARGET" -c:v libx264 -crf 16 -pix_fmt yuv420p \
    -c:a aac -b:a 192k "$OUT" -y
elif awk -v x="$DIFF" 'BEGIN{exit !(x > 0.01)}'; then
  echo "→ 不足，用尾帧补 ${DIFF}s 静帧"
  ffmpeg -v error -i "$TMP" -vf "tpad=stop_mode=clone:stop_duration=${DIFF}" \
    -af "apad=pad_dur=${DIFF}" -c:v libx264 -crf 16 -pix_fmt yuv420p -c:a aac -b:a 192k "$OUT" -y
else
  mv "$TMP" "$OUT"
fi

rm -f "$TMP"
FINAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
echo "完成: $OUT  (${FINAL}s)"
