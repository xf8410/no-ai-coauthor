# no-ai-coauthor —— AI 剥名闸

**一句话：AI 写代码可以，署名不行。三层防线把 Claude / Gemini / Copilot 塞的 `Co-Authored-By` 和 `🤖 Generated with` 全部剥掉或拒收。**

[![CI](https://github.com/xf8410/no-ai-coauthor/actions/workflows/no-ai-coauthor.yml/badge.svg)](https://github.com/xf8410/no-ai-coauthor/actions)
[![test](https://img.shields.io/badge/test-5%2F5-green)](#自测)

## 为什么

花钱用 AI 写代码，它反手在自己 commit 尾部塞：

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

GitHub 会在 commit 页给它挂头像徽章，等于**花钱给 AI 打广告、给它记功劳**。本仓三层防线治这个。

## 三层防线

| 层 | 机制 | 拦什么 | 怎么装 |
|---|---|---|---|
| **L1 hook**（本地） | `commit-msg` 钩子**静默剥离**署名行，commit 照常过 | AI 在本机的 git commit | `bash install.sh` 一次管全部 |
| **L2 workflow**（服务端） | CI 扫新 commit，含 AI 署名直接红 | 任何来源的 push（含别人的机器、云端 AI、`--no-verify` 绕过） | 拷 2 个文件进新仓 |
| **L3 官方开关**（源头） | Claude Code 自己的配置不再生成署名 | Claude Code | `~/.claude/settings.json` |

三层互补：L3 治源头但只管 Claude Code；L1 管本机所有 AI 但可被 `--no-verify` 绕过；L2 是铁闸，进仓必检。

## 新仓库接入（30 秒）

拷两个文件到新仓，commit，完事：

```
your-repo/
├── .github/workflows/no-ai-coauthor.yml   ← 从本仓 workflows/ 拷
└── scripts/scan.sh                        ← 从本仓 scripts/ 拷
```

从此任何带 AI 署名的 push 一律 CI 红，红着就合不了（配合分支保护/required check）。

一键（在新仓根目录跑）：

```bash
curl -fsSL https://raw.githubusercontent.com/xf8410/no-ai-coauthor/main/install-repo.sh | bash
```

## 存量仓库批量装（可选）

```bash
for repo in repo-a repo-b repo-c; do
  git clone "https://github.com/xf8410/$repo" "/tmp/$repo"
  curl -fsSL https://raw.githubusercontent.com/xf8410/no-ai-coauthor/main/install-repo.sh | bash -s -- "/tmp/$repo"
  cd "/tmp/$repo" && git add .github scripts && git commit -m "ci: 装 AI 剥名闸" && git push
done
```

## 本机全局 hook（可选，最丝滑）

```bash
bash install.sh
```

装完本机所有 `git commit` 都会先剥 AI 署名再落盘——AI 加了也白加，无感知、不报错、不烦 AI 重试。

> 注意：`core.hooksPath` 会绕过各仓库 `.git/hooks`（如 husky）。需要项目本地 hook 的仓跑 `git config core.hooksPath .git/hooks` 单独恢复。

## Claude Code 源头开关（可选）

```json
// ~/.claude/settings.json
{ "includeCoAuthoredBy": false }
```

老版本 CLI：`claude config set --global includeCoAuthoredBy false`

## 不误伤

- 人类 co-author（`Co-Authored-By: 张三 <...>`）**保留**——只拦 AI 名单（Claude/Gemini/Copilot/ChatGPT/GPT/Cursor）和 AI 邮箱（noreply@anthropic/google/openai.com）
- commit 正文里讨论 Claude（如"修复 Claude 建议的 bug"）不受影响——只剥 trailer 行，正文不动

## 已中招的历史 commit 怎么办

历史里的署名要重写 git 历史才能抹掉（`git filter-repo`），**会 force push、改全部分支的 commit hash**。量小建议留着（trailer 不影响 contributors 榜，那按作者邮箱算）；量大再重写，重写前先备份。

## 自测

```bash
bash test.sh   # 5 项：Claude 剥净 / Gemini 剥净 / 人类不误伤 / scan 拦截 / scan 放行
```
