#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${TIANCHUANGYA_BACKUP_ROOT:-$HOME/桌面/unbuntu美化/user-data-backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$BACKUP_ROOT/$STAMP"
ARCHIVE="$BACKUP_ROOT/tianchuangya-user-data-$STAMP.tar.zst"

say() {
  printf '\n[%s] %s\n' "backup-user-data" "$*"
}

need_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令：$1"
    echo "Ubuntu 可安装：sudo apt install -y $2"
    exit 1
  fi
}

need_tool tar tar
need_tool zstd zstd

mkdir -p "$OUT_DIR" "$BACKUP_ROOT"

say "生成备份清单：$OUT_DIR/include-list.txt"
{
  for name in 桌面 文档 下载 图片 视频 音乐 公共 模板; do
    [[ -e "$HOME/$name" ]] && printf '%s\n' "$name"
  done
  for path in \
    ".ssh" \
    ".gnupg" \
    ".gitconfig" \
    ".config/fcitx5" \
    ".config/xfce4" \
    ".config/Code/User" \
    ".config/google-chrome" \
    ".config/microsoft-edge" \
    ".local/share/applications" \
    ".local/share/gnome-shell/extensions" \
    ".local/share/fcitx5/themes" \
    ".themes" \
    ".icons" \
    ".local/bin"; do
    [[ -e "$HOME/$path" ]] && printf '%s\n' "$path"
  done
} | sort -u > "$OUT_DIR/include-list.txt"

say "记录系统状态"
{
  date
  uname -a
  lsb_release -a 2>/dev/null || true
  gnome-shell --version 2>/dev/null || true
} > "$OUT_DIR/system-info.txt"

if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f='${binary:Package}\t${Version}\n' > "$OUT_DIR/dpkg-packages.tsv" || true
fi
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application,name,version > "$OUT_DIR/flatpak-apps.tsv" || true
fi
if command -v snap >/dev/null 2>&1; then
  snap list > "$OUT_DIR/snap-list.txt" || true
fi
if command -v dconf >/dev/null 2>&1; then
  dconf dump / > "$OUT_DIR/dconf-user.ini" || true
fi

say "开始打包用户数据：$ARCHIVE"
tar \
  --create \
  --zstd \
  --file "$ARCHIVE" \
  --directory "$HOME" \
  --files-from "$OUT_DIR/include-list.txt" \
  --exclude='*/.cache/*' \
  --exclude='*/Cache/*' \
  --exclude='*/Code Cache/*' \
  --exclude='*/GPUCache/*' \
  --exclude='*/node_modules/*' \
  --exclude='*/build/*' \
  --exclude='*/dist/*' \
  --exclude='*/.gradle/*' \
  --exclude='*/Trash/*' \
  --warning=no-file-changed

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

say "备份完成：$ARCHIVE"
say "校验文件：$ARCHIVE.sha256"

if [[ -n "${TIANCHUANGYA_BACKUP_PASSWORD:-}" ]]; then
  need_tool openssl openssl
  ENC_ARCHIVE="$ARCHIVE.enc"
  say "检测到 TIANCHUANGYA_BACKUP_PASSWORD，开始加密备份包"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$ARCHIVE" -out "$ENC_ARCHIVE" -pass env:TIANCHUANGYA_BACKUP_PASSWORD
  sha256sum "$ENC_ARCHIVE" > "$ENC_ARCHIVE.sha256"
  rm -f "$ARCHIVE" "$ARCHIVE.sha256"
  say "加密备份完成：$ENC_ARCHIVE"
  say "加密校验文件：$ENC_ARCHIVE.sha256"
else
  say "提示：该备份包包含用户配置，可能含 SSH/GPG/浏览器配置。若要加密，可这样运行："
  echo "TIANCHUANGYA_BACKUP_PASSWORD='你的强密码' bash backup-user-data.sh"
fi
