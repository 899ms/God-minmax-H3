# God MiniMax H3
本视频由opnai.top生成

**把参考片拆成提示词，把提示词拼成成片。**

一个 MiniMax H3（海螺 3.0）的视频提示词库 + 可安装的 Agent Skill。
每条提示词都是从真实参考片逆向拆解、再用 H3 跑通验证的，
附带成片预览、API 参数和踩过的坑。

![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Model](https://img.shields.io/badge/MiniMax--H3-4~15s%20%C2%B7%202K%20%C2%B7%2024fps-F5FF60?labelColor=111)
![Prompts](https://img.shields.io/badge/提示词-5%20条-3158E8)

---

## 这个库解决什么

H3 单次生成上限 所有「30 秒成片」的需求，本质上都是三件事：

1. **分段生成** —— 15+14 还是 10+10+9，怎么切
2. **一致性接力** —— 尾帧接首帧 + 参考图 + 参考音频，怎么让人物跨段不变脸
3. **拼接** —— 音频交叉淡化，时长锁死到小数点后三位

这个库把这三件事写成了标准流程，外加 5 个已验证的分镜提示词模板。

---

## MiniMax H3 能做什么

2026 年 7 月 31 日发布。原生 2K / 24fps，**4–15 秒任意整数时长**，
音画同一次生成——环境声、动作音效、对白都落在你指定的那一拍上，
不是后期贴的音轨。

**全能参考**单次最多吃 9 张图 + 3 段视频 + 3 段音频，
用来锁角色的脸、服装、产品外观、运镜节奏和音色。

**最重要的能力跃迁：一条 prompt 里可以写多个分镜，H3 会自己切。**
2.x 是单镜头模型，H3 不是。本库的实测是：15 秒一条 prompt 塞进 11 个镜头，
包括结尾的英文标题卡，H3 完整还原。

---

## 仓库结构

| 路径 | 内容 |
|---|---|
| `SKILL.md` | Agent Skill 入口。丢给 Claude / Cursor 等支持 Skill 的客户端直接用 |
| `prompts/` | 5 条提示词模板，含 15 秒版与 29 秒分段版 |
| `references/h3-api.md` | API 速查：四种调用模式、限制、Context-IR、2K 再生成 |
| `references/prompt-grammar.md` | 提示词语法：四块结构、运镜标记表、音频指令写法 |
| `references/stitching.md` | 分段策略、一致性接力、ffmpeg 拼接 |
| `scripts/` | 尾帧导出、音轨抽取、一键拼接锁时长 |
| `assets/previews/` | 成片预览图 |

---

## 提示词库

### 1. FINAL BET —— 红黑白平面矢量动画

![FINAL BET](assets/previews/01-final-bet.webp)

正红 / 纯黑 / 纯白三色限定，日式角色 + 瑞士平面设计构图，网点半调质感。
15 秒里 11 个镜头，结尾自带 `FINAL BET · PLAY YOUR FATE` 标题卡。

**已验证** · 15s · 1344×768 · 文生视频 · [完整提示词 →](prompts/01-final-bet.md)

---

### 2. 第一人称手持超英 vlog

![Hero vlog](assets/previews/02-hero-vlog.webp)

技术核心是「手机自拍取景框 UI + 电影级动态范围 + 日落逆光」这套组合。
前半段伪 UGC 自拍，后半段取景框消失转客观镜头，落差就是钩子。

**已验证** · 15s · 1344×768 · 文生视频 · [完整提示词 →](prompts/02-hero-vlog.md)

---

### 3. NIGHT —— 美式硬派漫画 motion comic

![NIGHT](assets/previews/03-night-comic.webp)

核心手法是「版面即画面」：报纸拼贴、侦查板、六格分屏动作页，
平面排版语言直接当镜头用。午夜蓝 + 铬黄 + 警灯红。

**已验证** · 15s · 1344×768 · 文生视频 · [完整提示词 →](prompts/03-night-comic.md)

---

### 4. 史诗骑队开场 —— 长镜纵深

贴地低机位**固定镜头**，纵深压迫感全靠骑队由远及近产生。
很多人做史诗开场会本能地加推轨，反而把张力做没了。

待验证 · 29s（15+14）· [完整提示词 →](prompts/04-cavalry-opening.md)

---

### 5. 单镜头对白特写

越肩构图，零切点。考的不是运镜，是口型、微表情和眼神移动。
分段时接缝必须落在换气或转开视线的瞬间。

待验证 · 29s（15+14）· [完整提示词 →](prompts/05-single-take-dialogue.md)

---

## 怎么用

### 作为 Skill

支持 Agent Skill 的客户端，把整个仓库放进 skills 目录即可：

```bash
git clone https://github.com/LIUFelix2004/God-minmax-H3.git ~/.claude/skills/minimax-h3-video
```

之后提到「海螺」「H3 生成视频」「帮我做个 29 秒的片子」就会自动触发。

### 作为提示词库

直接翻 `prompts/`，复制 prompt 到海螺 App 或 Open Platform。
建议 **768P 试错 → 满意后走再生成接口出 2K**，省钱。

### 拼 29 秒成片

```bash
./scripts/extract_last_frame.sh segA.mp4          # 导出尾帧作下段 first_frame
./scripts/extract_audio.sh segA.mp4               # 抽音轨作下段 reference_audio
./scripts/stitch.sh 29 final.mp4 segA.mp4 segB.mp4  # 拼接 + 淡化 + 锁死 29.000s
```

---

## H3 提示词怎么写

从这几条片子的反复试错里总结的：

1. **风格锚点放最前面，每一段原样重写一遍。**模型跨段没有记忆，
   写「同上」等于没写。
2. **不写运镜就是固定机位死镜头。**每个分镜后面挂 `[推进]` `[横移]` `[跟随]`。
3. **配色要说死具体颜色。**「正红、纯黑、纯白三色，无渐变」比
   「高对比配色」有效十倍。
4. **音频要写三层**：环境底噪 + 动作音效 + 人声/配乐，并说明落在哪一拍。
   用音效标记剪辑点比形容节奏有用。
5. **一条 prompt 塞 8–12 个镜头是甜区。**超过就开始丢镜头，该分段了。
6. **参考素材管「是谁」，prompt 管「发生什么」。**别用文字描述脸，描述不住。
7. **一定要写负面约束。**多余肢体、变形面部、画面外文字、不必要的抖动。
8. **画面文字能少则少。**两个单词以内的英文标题卡成功率尚可，
   长文案一律后期加。

完整版见 [`references/prompt-grammar.md`](references/prompt-grammar.md)。

---

## 关于版权

本库只收录**自创设定**的提示词，不收录指向具体商业 IP 角色的提示词。

逆向拆解参考片时，真正值钱的是**画面语言**——配色方案、运镜逻辑、
剪辑节奏、构图法、材质质感。人物换成自己的设定，这套语言照样成立，
而且能拿去商用。

需要注意的是：有些角色特征组合在模型训练分布里高度指向某个知名 IP，
即使你写的是自创设定也会被画成那个样子。对策是主动加差异化特征并在
负面约束里排除，具体案例见 [`prompts/03-night-comic.md`](prompts/03-night-comic.md)。

---

## 参考

- [MiniMax 开放平台 · 视频生成文档](https://platform.minimaxi.com/docs/guides/video-generation)
- [awesome-minimax-h3-prompts](https://github.com/xianyu110/awesome-minimax-h3-prompts) —— 更大的社区提示词合集

## 贡献

跑通了新的模板，欢迎提 PR。请附上：完整 prompt、API 参数、成片预览图、
以及**失败过的地方**——坑比成功案例有用。

## 协议

[MIT](LICENSE)
