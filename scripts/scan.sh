#!/bin/sh
# no-ai-coauthor —— 扫描新增 commit 里的 AI 署名，发现即红（exit 1）
# CI 环境变量：EVENT / BEFORE / PR_BASE / SHA（GitHub Actions 注入，本地可手动模拟）
set -eu
EVENT="${EVENT:-}"
SHA="${SHA:-HEAD}"

if [ "$EVENT" = "pull_request" ] && [ -n "${PR_BASE:-}" ]; then
  RANGE="${PR_BASE}...${SHA}"
elif [ -n "${BEFORE:-}" ] && [ "$BEFORE" != "0000000000000000000000000000000000000000" ]; then
  RANGE="${BEFORE}..${SHA}"
  # force push / 异常时 before 可能失效，兜底最近 10 条
  git rev-parse --verify -q "${BEFORE}^{commit}" >/dev/null 2>&1 || RANGE="-10"
else
  RANGE="-10"
fi

echo "扫描范围: ${RANGE}"

BAD=$(git log --format='%h  %an <%ae>%n    %s%n%b' $RANGE 2>/dev/null | \
  grep -iE 'co-authored-by:[[:space:]]*(claude|gemini|copilot|chatgpt|gpt-|cursor)|co-authored-by:.*noreply@(anthropic|google|openai)\.com|generated with( \[)?(claude|gemini|copilot)' || true)

if [ -n "$BAD" ]; then
  echo "::error::发现 AI 署名（AI 写代码挂名的痕迹）——修复：本地跑 install.sh 装 hook，或手删 Co-Authored-By/Generated with 行后 amend 重推"
  echo ""
  echo "$BAD"
  exit 1
fi
echo "✓ 新 commit 无 AI 署名"
