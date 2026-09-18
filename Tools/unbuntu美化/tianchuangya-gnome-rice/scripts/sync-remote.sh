#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_URL="${1:-${TIANCHUANGYA_RICE_REMOTE:-}}"

say() {
  printf '\n[%s] %s\n' "sync-remote" "$*"
}

cd "$PACK_DIR"

if [[ ! -d .git ]]; then
  say "初始化 git 仓库"
  git init
fi

if [[ -n "$REMOTE_URL" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
  else
    git remote add origin "$REMOTE_URL"
  fi
fi

say "执行脚本语法检查"
for script in install.sh bootstrap.sh doctor.sh export-current-config.sh backup-user-data.sh restore-user-data.sh scripts/*.sh; do
  [[ -f "$script" ]] && bash -n "$script"
done

say "检查敏感信息"
if rg -n "github_pat_|ghp_|7d0ebd37a6854435fabe5bc06deaa180|GITHUB_TOKEN=\"[A-Za-z0-9_]{20,}|GITEE_TOKEN=\"[A-Za-z0-9_]{20,}" \
  --glob '!**/build/**' --glob '!**/.gradle/**' --glob '!*.apk' --glob '!*.tar.gz' --glob '!*.tar.zst' --glob '!*.enc' .; then
  echo "发现疑似真实 token，已停止。请先清理。"
  exit 1
fi

say "显示 git 状态"
git status --short

say "添加非忽略文件到暂存区"
git add .

if git diff --cached --quiet; then
  say "没有需要提交的变更"
else
  commit_msg="chore: update tianchuangya ubuntu rice $(date +%Y-%m-%d)"
  git commit -m "$commit_msg"
  say "已本地提交：$commit_msg"
fi

if git remote get-url origin >/dev/null 2>&1; then
  say "远程仓库：$(git remote get-url origin)"
  say "未自动 push。确认无误后手动运行：git push -u origin main"
else
  say "尚未配置远程仓库。可运行：bash sync-remote.sh https://gitee.com/你的用户名/仓库.git"
fi
