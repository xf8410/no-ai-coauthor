#!/bin/sh
# 一键安装全局 AI 剥名 hook（Linux / macOS / Termux）
# 原理：git config --global core.hooksPath 指到 ~/.githooks，
#       之后本机所有 git commit 都会先剥 AI 署名再落盘
# 注意：设置 hooksPath 后，各仓库 .git/hooks 里的本地 hook（如 husky）会被绕过；
#       需要项目本地 hook 的仓，往该仓跑：git config core.hooksPath .git/hooks 恢复
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)/hooks/no-ai-coauthor"
DEST_DIR="${HOME}/.githooks"
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/commit-msg"
chmod +x "$DEST_DIR/commit-msg"
git config --global core.hooksPath "$DEST_DIR"
echo "✓ 全局 hook 已装: $DEST_DIR/commit-msg"
echo "✓ core.hooksPath = $DEST_DIR"
echo ""
echo "自测: git commit -m 'test

Co-Authored-By: Claude <noreply@anthropic.com>' 后 git log -1 应无 Claude 字样"
