#!/usr/bin/env bash
# WhiteSur 图标主题安装脚本（macOS 风格系统图标 + 保留 AnimeApps 应用图标）
#
# 用法:  bash install-whitesur-icons.sh
# 逻辑:
#   1. 从 GitHub 下载 WhiteSur-icon-theme 源码
#   2. 安装到 ~/.local/share/icons（用户级，不需要 root）
#   3. 给 WhiteSur 的 index.theme 追加 AnimeApps 继承回退：
#      WhiteSur 缺失的应用图标会自动回退到现有 AnimeApps 二次元图标
#   4. 设置 gsettings 图标主题为 WhiteSur
set -euo pipefail

WORK=$(mktemp -d)
ICONS_DIR="$HOME/.local/share/icons"
THEME_NAME="WhiteSur"

echo ">> 下载 WhiteSur-icon-theme ..."
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$WORK/WhiteSur-icon-theme"

echo ">> 安装到 $ICONS_DIR ..."
cd "$WORK/WhiteSur-icon-theme"
bash install.sh -d "$ICONS_DIR" --bold

echo ">> 给 WhiteSur 追加 AnimeApps 图标回退 ..."
for variant in "$ICONS_DIR"/$THEME_NAME*; do
    index="$variant/index.theme"
    [ -f "$index" ] || continue
    if ! grep -q "AnimeApps" "$index"; then
        sed -i 's/^Inherits=\(.*\)$/Inherits=AnimeApps,\1/' "$index"
        echo "   patched $(basename "$variant")"
    fi
done

echo ">> 设置图标主题 ..."
gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME"

echo ">> 完成。桌面图标（DING）会在几秒内自动刷新；"
echo "   若未刷新，注销重登一次即可。"
