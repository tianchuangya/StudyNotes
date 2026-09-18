#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPORT_STAMP="$(date +%Y%m%d-%H%M%S)"

say() {
  printf '\n[%s] %s\n' "export-current-config" "$*"
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    say "已导出：$src"
  else
    say "跳过，不存在：$src"
  fi
}

say "导出当前 GNOME/输入法/终端/扩展配置到一键包"
mkdir -p "$PACK_DIR/configs/dconf" "$PACK_DIR/configs/gsettings" "$PACK_DIR/configs/fcitx5" \
  "$PACK_DIR/configs/xfce4/terminal" "$PACK_DIR/configs/applications" "$PACK_DIR/runtime-state"

if command -v dconf >/dev/null 2>&1; then
  dconf dump / > "$PACK_DIR/configs/dconf/user-$EXPORT_STAMP.ini" || true
  dconf dump /org/gnome/ > "$PACK_DIR/configs/dconf/org-gnome-latest.ini" || true
  say "已导出 dconf：configs/dconf/"
fi

if command -v gsettings >/dev/null 2>&1; then
  {
    gsettings get org.gnome.desktop.interface gtk-theme || true
    gsettings get org.gnome.desktop.interface icon-theme || true
    gsettings get org.gnome.desktop.interface cursor-theme || true
    gsettings get org.gnome.desktop.wm.preferences button-layout || true
    gsettings get org.gnome.shell favorite-apps || true
    gsettings get org.gnome.shell enabled-extensions || true
  } > "$PACK_DIR/configs/gsettings/core-latest.txt"
  say "已导出核心 gsettings：configs/gsettings/core-latest.txt"
fi

if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions list --enabled > "$PACK_DIR/configs/gsettings/enabled-extensions-latest.txt" || true
  gnome-extensions list > "$PACK_DIR/configs/gsettings/all-extensions-latest.txt" || true
  say "已导出扩展列表"
fi

copy_if_exists "$HOME/.config/fcitx5/config" "$PACK_DIR/configs/fcitx5/config"
copy_if_exists "$HOME/.config/fcitx5/profile" "$PACK_DIR/configs/fcitx5/profile"
copy_if_exists "$HOME/.local/share/fcitx5/themes/战双帕弥什 · 21号" "$PACK_DIR/fcitx5-themes/战双帕弥什 · 21号"
copy_if_exists "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" "$PACK_DIR/configs/xfce4/terminal/xfce4-terminal.xml"
copy_if_exists "$HOME/.local/share/applications/wechat.desktop" "$PACK_DIR/configs/applications/wechat.desktop"
copy_if_exists "$HOME/.local/share/gnome-shell/extensions/curtain-wallpaper@local" "$PACK_DIR/extensions/curtain-wallpaper@local"
copy_if_exists "$HOME/.local/share/gnome-shell/extensions/island-sync@local" "$PACK_DIR/island-sync/pc-extension/island-sync@local"
copy_if_exists "$HOME/.themes/LiquidGlassTransparent" "$PACK_DIR/themes/LiquidGlassTransparent"
copy_if_exists "$HOME/.local/share/icons/AnimeApps" "$PACK_DIR/icons/AnimeApps"
copy_if_exists "$HOME/.icons/nier_cursors" "$PACK_DIR/cursors/nier_cursors"

if [[ -L "$HOME/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper" ]]; then
  readlink "$HOME/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper" > "$PACK_DIR/runtime-state/current-desktop-wallpaper-link.txt"
fi
copy_if_exists "$HOME/.config/curtain-wallpaper-position" "$PACK_DIR/runtime-state/curtain-wallpaper-position"
copy_if_exists "$HOME/.config/island-sync-position" "$PACK_DIR/runtime-state/island-sync-position"

say "导出完成。建议运行：bash doctor.sh"
