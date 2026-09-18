#!/usr/bin/env bash
set -euo pipefail

PROJECT_URL="${1:-${TIANCHUANGYA_RICE_REPO:-}}"
TARGET_DIR="${2:-$HOME/桌面/unbuntu美化/tianchuangya-gnome-rice}"

say() {
  printf '\n[%s] %s\n' "bootstrap" "$*"
}

need_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    sudo -v
  fi
}

install_base_tools() {
  local missing=()
  for cmd in git curl tar zstd; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    say "安装基础工具：${missing[*]}"
    need_sudo
    sudo apt update
    sudo apt install -y git curl tar zstd
  fi
}

load_env() {
  if [[ -f "$TARGET_DIR/.env.local" ]]; then
    say "加载本机私有配置：$TARGET_DIR/.env.local"
    set -a
    # shellcheck disable=SC1091
    source "$TARGET_DIR/.env.local"
    set +a
  fi
}

clone_or_update() {
  if [[ -d "$TARGET_DIR/.git" ]]; then
    say "项目已存在，执行 git pull：$TARGET_DIR"
    git -C "$TARGET_DIR" pull --ff-only || {
      echo "git pull 失败。可能有本机修改，请先处理后重试。"
      exit 1
    }
    return
  fi

  if [[ -d "$TARGET_DIR" && -n "$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    say "目标目录已存在且非空，跳过 clone：$TARGET_DIR"
    return
  fi

  if [[ -z "$PROJECT_URL" ]]; then
    cat <<EOF
没有提供仓库地址。

用法：
  bash bootstrap.sh https://gitee.com/你的用户名/tianchuangya-gnome-rice.git

或：
  TIANCHUANGYA_RICE_REPO='https://...' bash bootstrap.sh
EOF
    exit 1
  fi

  say "克隆项目：$PROJECT_URL"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$PROJECT_URL" "$TARGET_DIR"
}

main() {
  install_base_tools
  clone_or_update
  load_env
  say "开始安装个人 Ubuntu 美化/恢复配置"
  bash "$TARGET_DIR/install.sh"
  say "安装后体检"
  bash "$TARGET_DIR/doctor.sh" || true
  say "完成。建议注销并重新登录一次。"
}

main "$@"
