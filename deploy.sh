#!/usr/bin/env bash
# 更新 git 並重新部署到本機 Docker。
# 用法：
#   ./deploy.sh                    # 預設從 upstream/main merge
#   REMOTE=origin ./deploy.sh      # 改從 origin/main merge
#   BRANCH=dev ./deploy.sh         # 改 merge 其他分支
set -euo pipefail

REMOTE="${REMOTE:-upstream}"
BRANCH="${BRANCH:-main}"
HEALTH_URL="${HEALTH_URL:-http://localhost:4173/api/tasks}"

cd "$(dirname "$0")"

step() { printf "\n\033[1;36m→ %s\033[0m\n" "$*"; }
ok()   { printf "\033[1;32m✓ %s\033[0m\n" "$*"; }
fail() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; }

# 1. 工作區必須乾淨（避免 merge 撞到本地未提交的修改）
if ! git diff-index --quiet HEAD --; then
  fail "工作區有未提交變更，請先 commit 或 stash"
  git status --short
  exit 1
fi

# 2. 確認 remote 存在
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  fail "找不到 remote「$REMOTE」，請先 git remote add $REMOTE <url>"
  exit 1
fi

# 3. fetch 後檢查是否有更新
step "git fetch $REMOTE"
git fetch "$REMOTE" --prune

remote_ref="$REMOTE/$BRANCH"
remote_sha=$(git rev-parse "$remote_ref")

if [ "$(git merge-base HEAD "$remote_ref")" = "$remote_sha" ]; then
  ok "$remote_ref 沒有新 commit，跳過 merge"
  has_git_update=0
else
  step "git merge $remote_ref"
  git log --oneline "HEAD..$remote_ref"
  if ! git merge "$remote_ref" --no-edit; then
    fail "Merge 衝突，請手動解決後重跑"
    exit 1
  fi
  ok "merge 完成"
  has_git_update=1
fi

# 4. 重 build + 起 container
step "docker compose up -d --build"
docker compose up -d --build

# 5. 健康檢查（最多等 10 秒）
step "健康檢查 $HEALTH_URL"
status="000"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  status=$(curl -sS -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")
  if [ "$status" = "200" ]; then
    if [ "$has_git_update" = "1" ]; then
      ok "部署完成（已套用 $remote_ref 新 commit）"
    else
      ok "部署完成（無新 commit，已重 build）"
    fi
    exit 0
  fi
done

fail "健康檢查未通過（最後 HTTP 狀態：$status）"
echo "  → docker compose logs --tail=50"
docker compose logs --tail=50
exit 1
