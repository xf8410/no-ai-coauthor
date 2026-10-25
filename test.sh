#!/bin/sh
# no-ai-coauthor 本地自测：hook 剥离 + scan 拦截 双向验证
# 用法：bash test.sh   （不碰任何真实仓库，全在 /tmp 造沙箱）
set -eu
cd "$(dirname "$0")"
HOOK="$(pwd)/hooks/no-ai-coauthor"
SCAN="$(pwd)/scripts/scan.sh"
T=$(mktemp -d /tmp/nac-test.XXXXXX)
trap 'rm -rf "$T"' EXIT

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ✓ $1"; }
bad()  { fail=$((fail+1)); echo "  ✗ $1"; }

echo "== 1) commit-msg hook：AI 署名被剥 =="
git init -q "$T/r1" && cd "$T/r1"
git config user.email t@t; git config user.name t
cp "$HOOK" .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
echo a > a.txt && git add a.txt
git commit -q -m "feat: 干活

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
if git log -1 --format=%B | grep -qiE 'claude|generated with|anthropic'; then
  bad "Claude 署名没剥干净"
else ok "Claude Code 署名（emoji行+Co-Authored-By）剥净"; fi

echo b > b.txt && git add b.txt
git commit -q -m "feat: 第二次干活

🤖 Generated with [Gemini CLI](https://github.com/google-gemini/gemini-cli)

Co-Authored-By: Gemini CLI <noreply@google.com>"
if git log -1 --format=%B | grep -qiE 'gemini|generated with|google'; then
  bad "Gemini 署名没剥干净"
else ok "Gemini CLI 署名剥净"; fi

echo "== 2) hook 不误伤人类 co-author =="
echo c > c.txt && git add c.txt
git commit -q -m "feat: 人类协作

Co-Authored-By: 张三 <zhangsan@example.com>"
if git log -1 --format=%B | grep -q "张三"; then
  ok "人类 co-author 保留"
else bad "人类 co-author 被误伤"; fi

echo "== 3) scan.sh：带署名的提交 → exit 1（CI 红） =="
cd "$T/r1"
echo dirty > dirty.txt && git add dirty.txt
git commit -q --no-verify -m "feat: 绕过hook的脏提交

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
if EVENT=push BEFORE=$(git rev-parse HEAD~1) SHA=$(git rev-parse HEAD) sh "$SCAN" >/dev/null 2>&1; then
  bad "scan 没拦住带署名历史"
else ok "scan 拦截生效（非零退出）"; fi

echo "== 4) scan.sh：干净提交 → exit 0 =="
git init -q "$T/r2" && cd "$T/r2"
git config user.email t@t; git config user.name t
echo x > x.txt && git add x.txt && git commit -q -m "clean: 无署名提交"
BEFORE=$(git rev-parse HEAD); echo y > y.txt && git add y.txt && git commit -q -m "clean: 又一条"
if EVENT=push BEFORE="$BEFORE" SHA=$(git rev-parse HEAD) sh "$SCAN" >/dev/null 2>&1; then
  ok "干净提交放行（exit 0）"
else bad "干净提交被误拦"; fi

echo ""
echo "结果: $pass 过 / $fail 挂"
[ "$fail" -eq 0 ]
