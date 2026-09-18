#!/usr/bin/env bash
set -u

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE=0

ok() { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; STATE=1; }
bad() { printf '❌ %s\n' "$*"; STATE=2; }
section() { printf '\n## %s\n' "$*"; }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then ok "命令存在：$1"; else warn "缺少命令：$1"; fi
}

check_path() {
  if [[ -e "$1" ]]; then ok "$2：$1"; else warn "$2 不存在：$1"; fi
}

gget() {
  gsettings get "$1" "$2" 2>/dev/null || printf '不可读'
}

section "系统"
date
uname -a
lsb_release -a 2>/dev/null || true
gnome-shell --version 2>/dev/null || warn "无法读取 gnome-shell 版本"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-未知}"

section "基础命令"
for cmd in gsettings gnome-extensions dconf fcitx5 fcitx5-remote xfce4-terminal curl tar zstd; do
  check_cmd "$cmd"
done

section "项目文件"
check_path "$PACK_DIR/install.sh" "一键安装脚本"
check_path "$PACK_DIR/scripts/export-current-config.sh" "导出脚本"
check_path "$PACK_DIR/scripts/backup-user-data.sh" "用户数据备份脚本"
check_path "$PACK_DIR/scripts/restore-user-data.sh" "用户数据恢复脚本"
check_path "$PACK_DIR/apk/island-sync-debug.apk" "灵动岛 APK"
check_path "$PACK_DIR/themes/LiquidGlassTransparent" "Shell 主题"
check_path "$PACK_DIR/extensions/curtain-wallpaper@local" "悬浮球扩展"
check_path "$PACK_DIR/island-sync/pc-extension/island-sync@local" "灵动岛电脑端扩展"

section "GNOME 设置"
if command -v gsettings >/dev/null 2>&1; then
  echo "gtk-theme: $(gget org.gnome.desktop.interface gtk-theme)"
  echo "icon-theme: $(gget org.gnome.desktop.interface icon-theme)"
  echo "cursor-theme: $(gget org.gnome.desktop.interface cursor-theme)"
  echo "button-layout: $(gget org.gnome.desktop.wm.preferences button-layout)"
  echo "favorite-apps: $(gget org.gnome.shell favorite-apps)"
  echo "enabled-extensions: $(gget org.gnome.shell enabled-extensions)"
fi

section "GNOME 扩展状态"
if command -v gnome-extensions >/dev/null 2>&1; then
  for ext in \
    user-theme@gnome-shell-extensions.gcampax.github.com \
    blur-my-shell@aunetx \
    dynamic-music-pill@andbal \
    clipboard-indicator@tudmotu.com \
    curtain-wallpaper@local \
    island-sync@local; do
    if gnome-extensions info "$ext" >/tmp/tianchuangya-ext-info 2>/dev/null; then
      status="$(rg -n '状态|State|已启用|Enabled' /tmp/tianchuangya-ext-info || true)"
      ok "$ext"
      [[ -n "$status" ]] && echo "$status"
    else
      warn "扩展不可用或未安装：$ext"
    fi
  done
fi

section "Fcitx5 / 微信输入"
check_path "$HOME/.config/fcitx5/profile" "Fcitx5 profile"
check_path "$HOME/.local/share/fcitx5/themes/战双帕弥什 · 21号" "Fcitx5 皮肤"
check_path "$HOME/.local/share/applications/wechat.desktop" "微信 desktop 启动项"
if command -v fcitx5-remote >/dev/null 2>&1; then
  fcitx5-remote >/dev/null 2>&1 && ok "Fcitx5 正在响应" || warn "Fcitx5 当前未响应"
fi

section "壁纸 / 悬浮球"
check_path "$HOME/壁纸" "壁纸目录"
check_path "$HOME/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper" "当前壁纸链接"
check_path "$HOME/.config/curtain-wallpaper-position" "悬浮球位置"
check_path "$HOME/.config/island-sync-position" "灵动岛位置"

section "Blur My Shell 动态玻璃"
BMS_SCHEMA="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
if [[ -d "$BMS_SCHEMA" ]]; then
  GSETTINGS_SCHEMA_DIR="$BMS_SCHEMA" gsettings get org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur 2>/dev/null | sed 's/^/dash static-blur: /' || true
  GSETTINGS_SCHEMA_DIR="$BMS_SCHEMA" gsettings get org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 2>/dev/null | sed 's/^/dash sigma: /' || true
  GSETTINGS_SCHEMA_DIR="$BMS_SCHEMA" gsettings get org.gnome.shell.extensions.blur-my-shell.popup static-blur 2>/dev/null | sed 's/^/popup static-blur: /' || true
else
  warn "未发现 blur-my-shell schemas"
fi

section "灵动岛 Gitee 配置"
ISLAND_SCHEMA="$HOME/.local/share/gnome-shell/extensions/island-sync@local/schemas"
if [[ -d "$ISLAND_SCHEMA" ]]; then
  GSETTINGS_SCHEMA_DIR="$ISLAND_SCHEMA" gsettings get org.gnome.shell.extensions.island-sync gitee-owner 2>/dev/null | sed 's/^/owner: /' || true
  GSETTINGS_SCHEMA_DIR="$ISLAND_SCHEMA" gsettings get org.gnome.shell.extensions.island-sync gitee-repo 2>/dev/null | sed 's/^/repo: /' || true
  GSETTINGS_SCHEMA_DIR="$ISLAND_SCHEMA" gsettings get org.gnome.shell.extensions.island-sync gitee-path 2>/dev/null | sed 's/^/path: /' || true
  GSETTINGS_SCHEMA_DIR="$ISLAND_SCHEMA" gsettings get org.gnome.shell.extensions.island-sync watch-apps 2>/dev/null | sed 's/^/watch-apps: /' || true
  token="$(GSETTINGS_SCHEMA_DIR="$ISLAND_SCHEMA" gsettings get org.gnome.shell.extensions.island-sync gitee-token 2>/dev/null || true)"
  if [[ "$token" == "''" || -z "$token" ]]; then warn "Gitee token 未配置"; else ok "Gitee token 已配置（不显示内容）"; fi
else
  warn "未发现 island-sync schemas"
fi

section "最近 GNOME Shell 扩展错误"
journalctl --user -b --no-pager 2>/dev/null | rg -n "Island Sync|island-sync|curtain-wallpaper|JS ERROR|Extension .*error" | tail -40 || true

section "结论"
if [[ "$STATE" -eq 0 ]]; then
  ok "体检未发现明显问题"
elif [[ "$STATE" -eq 1 ]]; then
  warn "体检发现警告，通常不阻塞使用"
else
  bad "体检发现错误，需要优先处理"
fi
exit "$STATE"
