#!/usr/bin/env bash
# 灵动岛同步 · APK 远程更新发布工具（contents 直存版）
#
# 一次执行完成：构建 APK → 计算 SHA256 → APK 作为仓库文件提交 → 提交 update.json。
# 不依赖 GitHub Release 附件（uploads.github.com 在部分网络不可达）。
# 下载直链走 raw.githubusercontent.com，public 仓库无需令牌即可下载。
#
# 前置：release/publish.conf 填好 GITHUB_OWNER / GITHUB_REPO / GITHUB_TOKEN，
#       令牌需要该仓库 Contents: Read and write 权限。
#
# 用法：./publish-update.sh --notes "更新说明"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../phone-android"
CONF="$SCRIPT_DIR/publish.conf"

[ -f "$CONF" ] || { echo "缺少 $CONF（复制 publish.conf.example 并填写）"; exit 1; }
# shellcheck disable=SC1090
source "$CONF"

: "${GITHUB_OWNER:?请在 publish.conf 填 GITHUB_OWNER}"
: "${GITHUB_REPO:?请在 publish.conf 填 GITHUB_REPO}"
: "${GITHUB_TOKEN:?请在 publish.conf 填 GITHUB_TOKEN}"
UPDATE_BRANCH="${UPDATE_BRANCH:-main}"

NOTES=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --notes) NOTES="$2"; shift 2 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done
[ -z "$NOTES" ] && NOTES="常规更新"

API="https://api.github.com"
AUTH=("Authorization: Bearer $GITHUB_TOKEN" "Accept: application/vnd.github+json")

echo ">> 1/5 构建 APK"
cd "$PROJECT_DIR"
"$HOME/.local/share/gradle-8.4/bin/gradle" :app:assembleDebug -q

APK="app/build/outputs/apk/debug/app-debug.apk"
[ -f "$APK" ] || { echo "构建产物不存在"; exit 1; }

VERSION_NAME=$(grep -oP 'versionName\s*=\s*"\K[^"]+' app/build.gradle.kts)
VERSION_CODE=$(grep -oP 'versionCode\s*=\s*\K[0-9]+' app/build.gradle.kts)
echo "   版本: v$VERSION_NAME (versionCode=$VERSION_CODE)"

echo ">> 2/5 计算 SHA256"
SHA256=$(sha256sum "$APK" | awk '{print $1}')
APK_NAME="island-sync-${VERSION_NAME}.apk"

# 通过 contents API 提交一个文件；输出 HTTP 码
put_file() {
    local path="$1" file="$2" message="$3"
    local sha body result_code
    sha=$(curl -s "$API/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$path?ref=$UPDATE_BRANCH" \
        -H "${AUTH[0]}" -H "${AUTH[1]}" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('sha',''))
except Exception: print('')")
    body=$(python3 - "$path" "$file" "$message" "$sha" "$UPDATE_BRANCH" << 'PYEOF'
import base64, json, sys
path, file, message, sha, branch = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
payload = {
    "message": message,
    "content": base64.b64encode(open(file, 'rb').read()).decode(),
    "branch": branch,
}
if sha:
    payload["sha"] = sha
print(json.dumps(payload))
PYEOF
)
    printf '%s' "$body" > /tmp/put-body.json
    result_code=$(curl -s -o /tmp/put-result.json -w "%{http_code}" -X PUT \
        "$API/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$path" \
        -H "${AUTH[0]}" -H "${AUTH[1]}" \
        --data-binary @/tmp/put-body.json)
    echo "$result_code"
}

echo ">> 3/5 发布 APK（Release 发行版优先，失败自动回退仓库直存）"
RELEASE_BODY=$(python3 -c 'import json,sys;print(json.dumps({"tag_name":sys.argv[1],"name":sys.argv[1],"body":sys.argv[2],"draft":False,"prerelease":False}))' "v$VERSION_NAME" "$NOTES")
RELEASE_ID=$(curl -s -X POST "$API/repos/$GITHUB_OWNER/$GITHUB_REPO/releases" \
    -H "${AUTH[0]}" -H "${AUTH[1]}" \
    -d "$RELEASE_BODY" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('id',''))
except Exception: print('')")

if [ -z "$RELEASE_ID" ]; then
    RELEASE_ID=$(curl -s "$API/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/tags/v$VERSION_NAME" \
        -H "${AUTH[0]}" -H "${AUTH[1]}" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('id',''))
except Exception: print('')")
fi

APK_URL=""
if [ -n "$RELEASE_ID" ]; then
    echo "   Release id=$RELEASE_ID，上传 APK 附件…"
    ASSET_STATE=$(curl -s --max-time 120 -X POST \
        "https://uploads.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/$RELEASE_ID/assets?name=$APK_NAME" \
        -H "${AUTH[0]}" -H "Content-Type: application/vnd.android.package-archive" \
        --data-binary @"$PROJECT_DIR/$APK" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('state',''))
except Exception: print('')")
    if [ "$ASSET_STATE" = "uploaded" ]; then
        APK_URL="https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/download/v$VERSION_NAME/$APK_NAME"
        echo "   ✅ Release 发行版上传成功"
    else
        echo "   ⚠️ Release 附件上传失败（uploads 域名不可达），回退仓库直存"
    fi
else
    echo "   ⚠️ 无法创建 Release，回退仓库直存"
fi

if [ -z "$APK_URL" ]; then
    CODE=$(put_file "$APK_NAME" "$PROJECT_DIR/$APK" "release: v$VERSION_NAME")
    [ "$CODE" = "201" ] || [ "$CODE" = "200" ] || { echo "APK 提交失败 (HTTP $CODE): $(cat /tmp/put-result.json | head -c 300)"; exit 1; }
    APK_URL="https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$UPDATE_BRANCH/$APK_NAME"
    echo "   仓库直存 HTTP $CODE"
fi

echo ">> 4/5 生成并提交 update.json"
UPDATE_JSON=$(python3 - "$VERSION_CODE" "$VERSION_NAME" "$APK_URL" "$SHA256" "$NOTES" << 'PYEOF'
import json, sys
code, name, url, sha, notes = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
print(json.dumps({
    "versionCode": int(code),
    "versionName": name,
    "url": url,
    "sha256": sha,
    "notes": notes,
}, ensure_ascii=False, indent=2))
PYEOF
)
echo "$UPDATE_JSON" > /tmp/update.json
CODE=$(put_file "update.json" "/tmp/update.json" "update: v$VERSION_NAME metadata")
[ "$CODE" = "201" ] || [ "$CODE" = "200" ] || { echo "update.json 提交失败 (HTTP $CODE): $(cat /tmp/put-result.json | head -c 300)"; exit 1; }
echo "   HTTP $CODE"

echo ">> 5/5 校验线上 update.json"
sleep 3
LIVE=$(curl -s "https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$UPDATE_BRANCH/update.json")
echo "$LIVE" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print('   线上版本: v%s (versionCode=%s)' % (d['versionName'], d['versionCode']))
print('   APK 直链: %s' % d['url'])
"
APK_URL=$(echo "$LIVE" | python3 -c "import json,sys;print(json.load(sys.stdin)['url'])")
curl -s -o /dev/null -w "   APK 可下载: HTTP %{http_code} (%{size_download} 字节预检)\n" "$APK_URL"

echo ""
echo "✅ 发布完成！手机端更新源："
echo "   https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$UPDATE_BRANCH/update.json"
