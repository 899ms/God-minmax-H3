# 分段生成与拼接

## 为什么必须分段

H3 单次上限 15 秒。任何超过 15 秒的成片都是拼的，没有别的路径。

## 时长切法

| 目标 | 切法 | 适合 |
|---|---|---|
| 20s | 10+10 | 双拍叙事 |
| 29s | 15+14 | 长镜头、对白、慢节奏 |
| 29s | 10+10+9 | 三幕（起—转—收），最通用 |
| 29s | 6+6+6+6+5 | 快闪蒙太奇、平面动画 |
| 30s | 15+15 | 最省事，接缝只有一个 |

**接缝位置比切法更重要。**放在这些地方：

- 场景切换处（最安全）
- 人物换气、转开视线的瞬间（对白片）
- 一记重音之后（有节奏的片子）

**绝对不要**把接缝放在句子中间、连续运镜的中途、或人物大幅动作的中段。

## 一致性接力三件套

### 1. 尾帧接首帧

```bash
ffmpeg -sseof -0.1 -i segA.mp4 -frames:v 1 -q:v 1 segA_last.jpg
```

把 `segA_last.jpg` 作为 segB 的 `role=first_frame`。

注意：图生视频模式下 `ratio` 恒为 `adaptive`，宽高比由这张图决定，
所以第一段的画幅就定死了全片画幅。

### 2. 角色定妆图

2–3 张同一角色的不同角度，作为 `role=reference_image` 传给**每一段**
（包括第一段）。别只给第二段——第一段自由发挥出来的脸，第二段追不上。

### 3. 参考音频

有人声就必传。把上一段的音轨抽出来：

```bash
ffmpeg -i segA.mp4 -vn -acodec libmp3lame -q:a 2 segA_audio.mp3
```

作为 `role=reference_audio`。不传的话第二段的音色基本会变成另一个人。

## 拼接

### 无损拼接（各段编码参数一致时）

```bash
cat > list.txt <<'EOF'
file 'segA.mp4'
file 'segB.mp4'
EOF

ffmpeg -f concat -safe 0 -i list.txt -c copy out_raw.mp4
```

### 带音频交叉淡化（推荐）

段间硬切音频会有明显的「啪」声。

```bash
ffmpeg -i segA.mp4 -i segB.mp4 -i segC.mp4 -filter_complex \
"[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a];\
 [a]afade=t=in:st=0:d=0.2,afade=t=out:st=28.8:d=0.2[ao]" \
-map "[v]" -map "[ao]" -c:v libx264 -crf 16 -preset slow -c:a aac -b:a 192k out.mp4
```

### 锁死精确时长

平台（视频号、抖音、小红书）有时对时长卡得很死。

```bash
# 多了就裁
ffmpeg -i out.mp4 -t 29 -c copy final.mp4

# 少了用尾帧补静帧（例：差 0.4s）
ffmpeg -i out.mp4 -vf tpad=stop_mode=clone:stop_duration=0.4 \
       -af apad=pad_dur=0.4 -c:v libx264 -crf 16 final.mp4

# 验收
ffprobe -v error -show_entries format=duration -of csv=p=0 final.mp4
```

29 秒 @ 24fps = 696 帧。

## 生成前的检查清单

- [ ] 上段尾帧已导出，作为本段 `first_frame`
- [ ] 角色定妆图已作为 `reference_image` 传入（图+视频+音频合计 ≤12 个文件）
- [ ] 有对白的话，上段音频已作为 `reference_audio` 传入
- [ ] 风格锚点在本段 prompt 里**原样重写了一遍**
- [ ] 各段 `duration` 相加正好等于目标时长
- [ ] 各段 `resolution` 与 `ratio` 完全一致
