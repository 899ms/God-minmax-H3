# MiniMax H3 API 速查

官方文档：https://platform.minimaxi.com/docs/guides/video-generation

## 两个模型

| | MiniMax-H3 | MiniMax-H3-Max |
|---|---|---|
| 定位 | 全模态，支持全能参考与视频编辑 | 与 fal.ai 联合出品，为速度优化 |
| 分辨率 | 768P / 2K | 480P / 768P |
| 时长 | 4–15 秒（整数） | 5–15 秒（整数） |
| 生成方式 | 文生 / 图生 / 首尾帧 / 全能参考 | 文生 / 图生 |

## 输入限制

- **首/尾帧**：图片 0/1/2 张；宽高 [256, 5760]；宽高比 5:2 ～ 2:5
- **全能参考**：图 ≤9 张；视频 ≤3 段（单段 2–15s，总 ≤15s）；音频 ≤3 段（单段 2–15s，总 ≤15s）；混合总计 ≤12 个文件
- **格式**：视频 H.264/H.265，内嵌音频 AAC/MP3；图片 JPG/PNG/WEBP/HEIC/HEIF；音频 WAV/MP3
- **大小**：视频单个 50MB，图片单个 30MB，音频单个 15MB；请求体 64MB（**推荐用 URL 传素材**）
- **提示词**：≤7000 字符

## 四种调用模式

异步三步：创建任务拿 `task_id` → 轮询状态 → 下载 `content.url`。

```python
import os, time, requests

api_key = os.environ["MINIMAX_API_KEY"]
headers = {"Authorization": f"Bearer {api_key}"}
BASE_URL = "https://api.minimaxi.com"
MODEL = "MiniMax-H3"


# 模式一：文生视频（ratio 必填，不能是 adaptive）
def text_to_video(prompt: str, duration: int = 15) -> str:
    payload = {
        "model": MODEL,
        "content": [{"type": "text", "text": prompt}],
        "duration": duration,
        "resolution": "2K",
        "ratio": "16:9",
    }
    r = requests.post(f"{BASE_URL}/v2/video_generation", headers=headers, json=payload)
    r.raise_for_status()
    return r.json()["task_id"]


# 模式二：首帧图 + 文本（宽高比由图片决定，ratio 恒为 adaptive）
def image_to_video(prompt: str, first_frame_url: str, duration: int = 15) -> str:
    payload = {
        "model": MODEL,
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": first_frame_url}, "role": "first_frame"},
        ],
        "duration": duration,
        "resolution": "2K",
    }
    r = requests.post(f"{BASE_URL}/v2/video_generation", headers=headers, json=payload)
    r.raise_for_status()
    return r.json()["task_id"]


# 模式三：首帧 + 尾帧
def start_end_to_video(prompt: str, first_url: str, last_url: str, duration: int = 15) -> str:
    payload = {
        "model": MODEL,
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": first_url}, "role": "first_frame"},
            {"type": "image_url", "image_url": {"url": last_url}, "role": "last_frame"},
        ],
        "duration": duration,
        "resolution": "2K",
    }
    r = requests.post(f"{BASE_URL}/v2/video_generation", headers=headers, json=payload)
    r.raise_for_status()
    return r.json()["task_id"]


# 模式四：全能参考（图 / 视频 / 音频可组合）
def reference_to_video(prompt: str, image_urls=(), video_urls=(), audio_urls=(), duration: int = 15) -> str:
    content = [{"type": "text", "text": prompt}]
    for u in image_urls:
        content.append({"type": "image_url", "image_url": {"url": u}, "role": "reference_image"})
    for u in video_urls:
        content.append({"type": "video_url", "video_url": {"url": u}, "role": "reference_video"})
    for u in audio_urls:
        content.append({"type": "audio_url", "audio_url": {"url": u}, "role": "reference_audio"})
    payload = {"model": MODEL, "content": content, "duration": duration, "resolution": "2K"}
    r = requests.post(f"{BASE_URL}/v2/video_generation", headers=headers, json=payload)
    r.raise_for_status()
    return r.json()["task_id"]


# 轮询（建议间隔 10 秒）
def wait(task_id: str) -> str:
    while True:
        time.sleep(10)
        r = requests.get(f"{BASE_URL}/v2/query/video_generation/{task_id}", headers=headers)
        r.raise_for_status()
        task = r.json()["task"]
        if task["status"] == "succeeded":
            return task["content"]["url"]
        if task["status"] in ("failed", "cancelled"):
            raise RuntimeError(f"{task['status']}: {task.get('error')}")


def download(url: str, path: str):
    with open(path, "wb") as f:
        f.write(requests.get(url).content)
```

## 两个容易漏掉的接口

**H3-Context-IR** — 只返回增强后的提示词，不生成视频。把你的草稿丢进去，
它会理解多模态上下文、补齐语义细节再吐回来。写长 prompt 时值得先过一道。
任务类型 `task_type=h3_context_ir`，结果在 `content.prompt`。

**视频再生成** — 已有符合 768P 规格的成片，可以调再生成接口输出 2K。
请求时要**原样提交生成 768P 时的全部 `content`**，额外且仅额外加入一个
`type=video_url`、`role=base_video` 的源视频项。任务类型 `task_type=regeneration`。

工作流建议：**768P 试错 → 满意后再生成 2K**，省钱。
