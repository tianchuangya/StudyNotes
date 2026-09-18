#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.local/share/tianchuangya-gnome-rice/backups/$(date +%Y%m%d-%H%M%S)"
STATE_DIR="$HOME/.local/share/codex-gnome-liquid-glass"
WALLPAPER_DIR="$HOME/壁纸"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/tianchuangya-default-wallpaper.jpg"
CURRENT_WALLPAPER="$STATE_DIR/current-desktop-wallpaper"

say() {
  printf '\n[%s] %s\n' "tianchuangya-rice" "$*"
}

need_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    sudo -v
  fi
}

install_apt_packages() {
  local missing=()
  for pkg in gnome-tweaks gnome-shell-extensions xfce4-terminal curl ca-certificates rsync zstd dconf-cli desktop-file-utils fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if ((${#missing[@]})); then
    say "安装系统依赖：${missing[*]}"
    need_sudo
    sudo apt update
    sudo apt install -y "${missing[@]}"
  else
    say "系统依赖已满足"
  fi
}

install_yesplaymusic() {
  if command -v yesplaymusic >/dev/null 2>&1; then
    say "YesPlayMusic 已安装，跳过下载"
    return
  fi

  say "下载并安装 YesPlayMusic 最新 amd64 deb"
  need_sudo
  local api url deb
  api="https://api.github.com/repos/qier222/YesPlayMusic/releases/latest"
  url="$(curl -fsSL "$api" | grep -Eo 'https://[^"]+amd64\.deb' | head -n 1 || true)"
  if [[ -z "$url" ]]; then
    echo "没有在 YesPlayMusic 最新 release 中找到 amd64 deb。"
    echo "请手动下载后重跑脚本，或把 deb 放进本目录。"
    return 0
  fi
  deb="$(mktemp --suffix=.deb)"
  curl -fL "$url" -o "$deb"
  sudo apt install -y "$deb"
}

install_wechat() {
  if command -v wechat >/dev/null 2>&1 || [[ -x /opt/wechat/wechat ]]; then
    say "微信已安装，跳过安装"
    return
  fi

  say "安装微信 Linux 版，用于后续写入 Fcitx5 启动环境"
  need_sudo
  if apt-cache show wechat >/dev/null 2>&1; then
    sudo apt install -y wechat
    return
  fi

  local deb tmp_dir
  tmp_dir="$(mktemp -d)"
  deb="$tmp_dir/WeChatLinux_x86_64.deb"
  local url="${WECHAT_DEB_URL:-https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb}"
  if curl -fL "$url" -o "$deb"; then
    sudo apt install -y "$deb"
  else
    echo "没有下载到微信 deb。你可以先从 https://linux.weixin.qq.com/ 手动安装微信，再重跑本脚本。"
    return 0
  fi
}

backup_current_config() {
  say "备份当前配置到 $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  for path in \
    "$HOME/.themes/LiquidGlassTransparent" \
    "$HOME/.local/share/gnome-shell/extensions/curtain-wallpaper@local" \
    "$HOME/.local/share/gnome-shell/extensions/island-sync@local" \
    "$HOME/.local/share/icons/AnimeApps" \
    "$HOME/.icons/nier_cursors" \
    "$HOME/.config/fcitx5" \
    "$HOME/.local/share/fcitx5/themes/战双帕弥什 · 21号" \
    "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" \
    "$HOME/.local/share/applications/wechat.desktop"; do
    if [[ -e "$path" ]]; then
      mkdir -p "$BACKUP_DIR/$(dirname "${path#$HOME/}")"
      cp -a "$path" "$BACKUP_DIR/${path#$HOME/}"
    fi
  done
}

copy_assets() {
  say "复制主题、图标、鼠标、扩展和脚本"
  mkdir -p "$HOME/.themes" "$HOME/.local/share/gnome-shell/extensions" "$HOME/.local/share/icons" "$HOME/.icons" "$HOME/.local/bin"
  cp -a "$PACK_DIR/themes/LiquidGlassTransparent" "$HOME/.themes/"
  cp -a "$PACK_DIR/extensions/curtain-wallpaper@local" "$HOME/.local/share/gnome-shell/extensions/"
  cp -a "$PACK_DIR/icons/AnimeApps" "$HOME/.local/share/icons/"
  cp -a "$PACK_DIR/cursors/nier_cursors" "$HOME/.icons/"
  cp -a "$PACK_DIR/scripts/." "$HOME/.local/bin/" 2>/dev/null || true
  chmod +x "$HOME/.local/bin/random-anime-wallpaper" "$HOME/.local/bin/random-app-wallpaper" "$HOME/.local/bin/random-nautilus" "$HOME/.local/bin/restart-curtain-wallpaper" "$HOME/.local/bin/export-current-config.sh" "$HOME/.local/bin/backup-user-data.sh" "$HOME/.local/bin/restore-user-data.sh" "$HOME/.local/bin/doctor.sh" 2>/dev/null || true
}

setup_island_sync() {
  if [[ ! -d "$PACK_DIR/island-sync/pc-extension/island-sync@local" ]]; then
    return
  fi

  say "安装灵动岛手机互通扩展 island-sync@local"
  local dest="$HOME/.local/share/gnome-shell/extensions/island-sync@local"
  mkdir -p "$dest"
  cp -a "$PACK_DIR/island-sync/pc-extension/island-sync@local/." "$dest/"
  glib-compile-schemas "$dest/schemas/" 2>/dev/null || true

  if [[ -n "${ISLAND_SYNC_GITEE_OWNER:-}" ]]; then
    GSETTINGS_SCHEMA_DIR="$dest/schemas" gsettings set org.gnome.shell.extensions.island-sync gitee-owner "$ISLAND_SYNC_GITEE_OWNER" || true
  fi
  if [[ -n "${ISLAND_SYNC_GITEE_REPO:-}" ]]; then
    GSETTINGS_SCHEMA_DIR="$dest/schemas" gsettings set org.gnome.shell.extensions.island-sync gitee-repo "$ISLAND_SYNC_GITEE_REPO" || true
  fi
  if [[ -n "${ISLAND_SYNC_GITEE_TOKEN:-}" ]]; then
    GSETTINGS_SCHEMA_DIR="$dest/schemas" gsettings set org.gnome.shell.extensions.island-sync gitee-token "$ISLAND_SYNC_GITEE_TOKEN" || true
  fi
}

apply_blur_my_shell_patches() {
  local bms_dir="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx"
  if [[ ! -d "$bms_dir" || ! -d "$PACK_DIR/blur-my-shell-patches" ]]; then
    say "未检测到 blur-my-shell 本地扩展，跳过定制补丁复制"
    return
  fi

  say "应用 blur-my-shell 动态玻璃圆角补丁"
  mkdir -p "$bms_dir/conveniences" "$bms_dir/components/popup" "$bms_dir/components"
  cp -a "$PACK_DIR/blur-my-shell-patches/dynamic_corner.js" "$bms_dir/conveniences/dynamic_corner.js"
  cp -a "$PACK_DIR/blur-my-shell-patches/blur_surface.js" "$bms_dir/components/popup/blur_surface.js"
  cp -a "$PACK_DIR/blur-my-shell-patches/dash_to_dock.js" "$bms_dir/components/dash_to_dock.js"
}

setup_fcitx5() {
  say "配置 Fcitx5 输入法和皮肤"
  mkdir -p "$HOME/.config/fcitx5" "$HOME/.local/share/fcitx5/themes"
  cp -a "$PACK_DIR/configs/fcitx5/." "$HOME/.config/fcitx5/"
  cp -a "$PACK_DIR/fcitx5-themes/战双帕弥什 · 21号" "$HOME/.local/share/fcitx5/themes/"
  im-config -n fcitx5 2>/dev/null || true
  fcitx5-remote -r 2>/dev/null || true
}

setup_wallpaper() {
  say "配置统一壁纸入口"
  mkdir -p "$STATE_DIR" "$WALLPAPER_DIR"
  cp -a "$PACK_DIR/wallpapers/default-wallpaper.jpg" "$DEFAULT_WALLPAPER"
  ln -sfn "$DEFAULT_WALLPAPER" "$CURRENT_WALLPAPER"
  local uri
  uri="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$DEFAULT_WALLPAPER")"
  gsettings set org.gnome.desktop.background picture-uri "$uri"
  gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
}

setup_xfce_terminal() {
  say "配置 XFCE Terminal 背景和配色"
  local cfg_dir cfg_file
  cfg_dir="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
  cfg_file="$cfg_dir/xfce4-terminal.xml"
  mkdir -p "$cfg_dir"
  cp -a "$PACK_DIR/configs/xfce4/terminal/xfce4-terminal.xml" "$cfg_file"
  sed -i "s#/home/tianchuangya#$HOME#g" "$cfg_file"
}

setup_wechat_input() {
  say "修复微信 Fcitx5 输入法启动环境"
  mkdir -p "$HOME/.local/share/applications"
  cp -a "$PACK_DIR/configs/applications/wechat.desktop" "$HOME/.local/share/applications/wechat.desktop"
  sed -i "s#/home/tianchuangya#$HOME#g" "$HOME/.local/share/applications/wechat.desktop"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
}

setup_gnome_settings() {
  say "写入 GNOME 主题、Dock、窗口按钮和顶栏插件位置"
  gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' || true
  gsettings set org.gnome.desktop.interface icon-theme 'AnimeApps'
  gsettings set org.gnome.desktop.interface cursor-theme 'nier_cursors'
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
  gsettings set org.gnome.shell.extensions.user-theme name 'LiquidGlassTransparent'
  gsettings set org.gnome.shell favorite-apps "['microsoft-edge.desktop', 'wechat.desktop', 'org.gnome.Nautilus.desktop', 'snap-store_snap-store.desktop', 'qq.desktop', 'code_code.desktop', 'idea.desktop']"

  if gsettings writable org.gnome.shell.extensions.dash-to-dock dock-position >/dev/null 2>&1; then
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 44
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0
    gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
    gsettings set org.gnome.shell.extensions.dash-to-dock show-trash true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
  fi

  if [[ -d "$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" ]]; then
    local bms_schema_dir
    bms_schema_dir="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur false || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 4 || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock brightness 0.72 || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock corner-radius 32 || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.popup static-blur false || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.popup sigma 6 || true
    GSETTINGS_SCHEMA_DIR="$bms_schema_dir" gsettings set org.gnome.shell.extensions.blur-my-shell.popup brightness 0.75 || true
  fi

  if [[ -d "$HOME/.local/share/gnome-shell/extensions/dynamic-music-pill@andbal/schemas" ]]; then
    local schema_dir
    schema_dir="$HOME/.local/share/gnome-shell/extensions/dynamic-music-pill@andbal/schemas"
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill position-mode 3 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill target-container 0 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill horizontal-offset 0 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill vertical-offset -1 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill panel-pill-width 250 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill panel-pill-height 28 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill panel-art-size 22 || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill hide-default-player true || true
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.dynamic-music-pill show-album-art true || true
  fi
}

enable_extensions() {
  say "启用 GNOME 扩展"
  local extensions=(
    user-theme@gnome-shell-extensions.gcampax.github.com
    blur-my-shell@aunetx
    dynamic-music-pill@andbal
    clipboard-indicator@tudmotu.com
    curtain-wallpaper@local
    island-sync@local
  )
  for ext in "${extensions[@]}"; do
    gnome-extensions enable "$ext" 2>/dev/null || true
  done
}

main() {
  install_apt_packages
  install_wechat
  install_yesplaymusic
  backup_current_config
  copy_assets
  setup_wallpaper
  setup_island_sync
  apply_blur_my_shell_patches
  setup_fcitx5
  setup_xfce_terminal
  setup_wechat_input
  setup_gnome_settings
  enable_extensions
  say "完成。建议注销并重新登录一次，让 Shell 主题、扩展和终端配置完全刷新。"
}

main "$@"
