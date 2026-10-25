#!/bin/sh
# 一键给单个仓库装 no-ai-coauthor CI 闸（拷 workflow + scan 脚本）
# 用法：install-repo.sh [仓库目录]   （默认当前目录）
set -eu
DIR="${1:-.}"
cd "$DIR"
[ -d .git ] || { echo "✗ 不是 git 仓库: $DIR"; exit 1; }
mkdir -p .github/workflows scripts
BASE="https://raw.githubusercontent.com/xf8410/no-ai-coauthor/main"
curl -fsSL "$BASE/.github/workflows/no-ai-coauthor.yml" -o .github/workflows/no-ai-coauthor.yml
curl -fsSL "$BASE/scripts/scan.sh" -o scripts/scan.sh
chmod +x scripts/scan.sh
echo "✓ 已装：.github/workflows/no-ai-coauthor.yml + scripts/scan.sh"
echo "  下一步：git add .github scripts && git commit -m 'ci: 装 AI 剥名闸' && git push"
