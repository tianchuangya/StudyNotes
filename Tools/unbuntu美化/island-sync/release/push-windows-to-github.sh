#!/bin/bash
# 网络恢复后运行：把 Windows 接收端 + CI 工作流推到 island-sync-updates 仓库
set -e
TOKEN=$(grep GITHUB_TOKEN ~/桌面/unbuntu美化/island-sync/release/publish.conf | cut -d'"' -f2)
push() {
  local path="$1" file="$2" msg="$3" sha code
  sha=$(curl -s --max-time 20 "https://api.github.com/repos/tianchuangya/island-sync-updates/contents/$path" -H "Authorization: Bearer $TOKEN" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('sha',''))
except: print('')" 2>/dev/null) || sha=""
  python3 -c "
import base64, json, sys
p = {'message': sys.argv[3], 'content': base64.b64encode(open(sys.argv[2],'rb').read()).decode(), 'branch': 'main'}
if sys.argv[1]: p['sha'] = sys.argv[1]
print(json.dumps(p))" "$sha" "$file" "$msg" > /tmp/pb.json
  code=$(curl -s --max-time 30 -o /dev/null -w "%{http_code}" -X PUT \
    "https://api.github.com/repos/tianchuangya/island-sync-updates/contents/$path" \
    -H "Authorization: Bearer $TOKEN" --data-binary @/tmp/pb.json)
  echo "$path → $code"
  [ "$code" = "200" ] || [ "$code" = "201" ]
}
D=~/桌面/unbuntu美化/island-sync/windows-receiver
push "windows-receiver/island_sync_receiver.py" "$D/island_sync_receiver.py" "feat: windows receiver"
push "windows-receiver/config.example.json" "$D/config.example.json" "feat: config"
mkdir -p /tmp/wf && cp ~/桌面/unbuntu美化/island-sync/windows-receiver/build-windows.yml /tmp/wf/ 2>/dev/null || true
push ".github/workflows/build-windows.yml" ~/桌面/unbuntu美化/island-sync/windows-receiver/build-windows.yml "ci: build exe"
echo "全部推送完成。去仓库 Actions 页面手动运行 Build Windows Receiver 即可得到 EXE。"
