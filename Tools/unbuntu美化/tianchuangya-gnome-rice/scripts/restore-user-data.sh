#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="${1:-}"
RESTORE_ROOT="${TIANCHUANGYA_RESTORE_ROOT:-$HOME}"
SAFETY_DIR="$HOME/.local/share/tianchuangya-gnome-rice/restore-safety/$(date +%Y%m%d-%H%M%S)"
DECRYPTED_ARCHIVE=""

say() {
  printf '\n[%s] %s\n' "restore-user-data" "$*"
}

usage() {
  cat <<'USAGE'
用法：
  bash restore-user-data.sh /path/to/tianchuangya-user-data-YYYYmmdd-HHMMSS.tar.zst

默认恢复到当前用户 HOME。
如需恢复到临时目录：
  TIANCHUANGYA_RESTORE_ROOT=/tmp/restore-test bash restore-user-data.sh 备份包.tar.zst
USAGE
}

if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  usage
  exit 1
fi

if ! command -v zstd >/dev/null 2>&1; then
  echo "缺少 zstd：sudo apt install -y zstd"
  exit 1
fi

cleanup() {
  [[ -n "$DECRYPTED_ARCHIVE" && -f "$DECRYPTED_ARCHIVE" ]] && rm -f "$DECRYPTED_ARCHIVE"
}
trap cleanup EXIT

if [[ "$ARCHIVE" == *.enc ]]; then
  if ! command -v openssl >/dev/null 2>&1; then
    echo "缺少 openssl：sudo apt install -y openssl"
    exit 1
  fi
  if [[ -z "${TIANCHUANGYA_BACKUP_PASSWORD:-}" ]]; then
    echo "这是加密备份，请先设置 TIANCHUANGYA_BACKUP_PASSWORD。"
    echo "示例：TIANCHUANGYA_BACKUP_PASSWORD='你的强密码' bash restore-user-data.sh '$ARCHIVE'"
    exit 1
  fi
  DECRYPTED_ARCHIVE="$(mktemp --suffix=.tar.zst)"
  say "解密备份包到临时文件"
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$ARCHIVE" -out "$DECRYPTED_ARCHIVE" -pass env:TIANCHUANGYA_BACKUP_PASSWORD
  ARCHIVE="$DECRYPTED_ARCHIVE"
fi

if [[ -f "$ARCHIVE.sha256" ]]; then
  say "校验 sha256"
  sha256sum -c "$ARCHIVE.sha256"
fi

say "恢复目标：$RESTORE_ROOT"
say "冲突文件会先备份到：$SAFETY_DIR"
mkdir -p "$SAFETY_DIR" "$RESTORE_ROOT"

TMP_LIST="$(mktemp)"
tar --zstd --list --file "$ARCHIVE" > "$TMP_LIST"

while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  target="$RESTORE_ROOT/$item"
  if [[ -e "$target" ]]; then
    mkdir -p "$SAFETY_DIR/$(dirname "$item")"
    mv "$target" "$SAFETY_DIR/$item"
  fi
done < "$TMP_LIST"
rm -f "$TMP_LIST"

say "开始解包"
tar --extract --zstd --file "$ARCHIVE" --directory "$RESTORE_ROOT"

say "恢复完成"
say "旧文件安全备份位置：$SAFETY_DIR"
