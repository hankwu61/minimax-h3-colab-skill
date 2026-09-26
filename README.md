# MiniMax H3 Colab Skill

This repository is a standalone Codex skill for creating short MiniMax H3 Ref2VA videos from local reference images through Google Colab. It includes the skill instructions, the inference notebook, a Python runner, a shell launcher, an idempotent installer, and runner tests.

本儲存庫是可獨立使用的 Codex 技能，用於透過 Google Colab 將本機參照圖片製作成短篇 MiniMax H3 Ref2VA 影片。內容包含技能指示、推論 Notebook、Python runner、Shell 啟動器、可重複執行的安裝程式，以及 runner 測試。

## Documentation

- [繁體中文完整說明](README.zh-TW.md)
- [Full English documentation](README.en.md)

## Quick start / 快速開始

```bash
git clone <repository-url> minimax-h3-colab-skill
cd minimax-h3-colab-skill
./install.sh
uv python install 3.12
uv tool install --python 3.12 google-colab-cli
colab --auth=oauth2 usage
```

The runner itself supports Python 3.11 and newer. The current Google Colab CLI
release needs Python 3.12 or newer; `uv python install` supplies it without
changing the Studio or system Python.

第一次執行 `usage` 時，Colab CLI 會引導 Google OAuth2 授權。完成授權後，可用下列命令啟動一次推論：

After OAuth2 is complete, run one inference with:

```bash
./run_colab_inference.sh \
  --image /absolute/path/reference.png \
  --prompt /absolute/path/prompt.txt \
  --output /absolute/path/result.mp4
```

可重複傳入 1–9 個 `--image`；順序會對應 prompt 中的 `<Picture 1>` 至 `<Picture 9>`。`prompt.txt` 會以 UTF-8 原文上傳並傳給 Notebook。

Repeat `--image` for 1–9 ordered references. Their order maps to `<Picture 1>` through `<Picture 9>`, and the UTF-8 prompt file is uploaded verbatim to the notebook.

The runner uses Colab compute units and remote GPU allocation. It does not run the H3 model on the local computer. See the language-specific README for prerequisites, batch manifests, session behavior, limits, and troubleshooting.
