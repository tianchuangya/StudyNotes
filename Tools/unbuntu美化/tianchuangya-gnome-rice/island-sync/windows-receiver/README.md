# Windows 接收端（由 是天创呀 制作）

接收手机推送的通知，弹 Windows 系统通知；手机剪贴板自动进电脑剪贴板。

## 直接使用
1. `config.example.json` 复制为 `config.json`，填 Gitee 仓库信息
2. 安装 Python（3.8+）后运行：`python island_sync_receiver.py`
3. 想要 EXE：仓库 Actions 页运行 "Build Windows Receiver"，或在 Windows 上
   `pip install pyinstaller && pyinstaller --onefile --noconsole island_sync_receiver.py`

## 打包 EXE 的自动构建
`.github/workflows/build-windows.yml` 已就绪：推送到 updates 仓库后，
在 Actions 页面手动运行，或推一个 `win*` 标签，自动产出 IslandSyncReceiver.exe。
（文件推送：网络恢复后运行 `release/push-windows-to-github.sh`）
