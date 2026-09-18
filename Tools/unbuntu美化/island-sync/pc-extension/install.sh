#!/usr/bin/env bash
# 灵动岛同步 · 电脑端扩展安装（用户级，无需 root）
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/island-sync@local"
DEST="$HOME/.local/share/gnome-shell/extensions/island-sync@local"

if [ ! -d "$SRC" ]; then
    echo "错误：请在 island-sync/pc-extension 目录下运行本脚本"
    exit 1
fi

echo ">> 复制扩展到 $DEST"
mkdir -p "$DEST"
cp -r "$SRC/." "$DEST/"

echo ">> 编译 GSettings schema"
glib-compile-schemas "$DEST/schemas/"

echo ">> 启用扩展"
python3 - <<'PY'
import ast
import subprocess

uuid = 'island-sync@local'
raw = subprocess.check_output(
    ['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
    text=True,
).strip()
try:
    enabled = ast.literal_eval(raw)
except Exception:
    enabled = []
if uuid not in enabled:
    enabled.append(uuid)
subprocess.check_call([
    'gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', repr(enabled)
])
PY

echo ">> 完成。面板右上角会出现手机图标（灵动岛同步）。"
echo "   打开扩展设置（扩展 app → 灵动岛同步 → 设置）填写 Gitee 仓库与令牌。"
echo "   若面板图标未出现，注销重登一次。"
