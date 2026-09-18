#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵动岛同步 · Windows 接收端（天创呀 © 2026）
轮询 Gitee 仓库的 island.json，新通知弹出 Windows 系统通知（Toast）。

用法：
  1. 复制 config.example.json 为 config.json，填入 Gitee 仓库信息
  2. python island_sync_receiver.py   （或用 PyInstaller 打包成 EXE）
     pyinstaller --onefile --noconsole island_sync_receiver.py
"""
import json
import base64
import ctypes
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

CONFIG_PATH = Path(__file__).parent / "config.json"
STATE_PATH = Path(__file__).parent / ".last_seen"


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def http_get(url, token=""):
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"token {token}")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read().decode("utf-8")


def load_config():
    cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    return cfg


def fetch_state(cfg):
    """读取 island.json；返回 (last_id, notifications, clipboard)"""
    owner, repo = cfg["gitee_owner"], cfg["gitee_repo"]
    branch, path = cfg.get("gitee_branch", "master"), cfg.get("gitee_path", "island.json")
    token = cfg.get("gitee_token", "")
    # 优先 raw 直链（public 仓库免 token），失败回退 contents API
    try:
        url = f"https://gitee.com/{owner}/{repo}/raw/{branch}/{path}"
        if token:
            url += f"?access_token={token}"
        text = http_get(url)
    except Exception:
        url = f"https://gitee.com/api/v5/repos/{owner}/{repo}/contents/{path}?ref={branch}"
        if token:
            url += f"&access_token={token}"
        data = json.loads(http_get(url, token))
        text = base64.b64decode(data.get("content", "")).decode("utf-8")
    state = json.loads(text)
    notifs = state.get("notifications", [])
    last_id = notifs[-1]["id"] if notifs else None
    return last_id, notifs, state.get("clipboard")


def toast(title, body, app=""):
    """Windows 10/11 系统通知（PowerShell 调用系统 Toast API，无第三方依赖）"""
    ps = f'''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template=\\"ToastGeneric\\"><text>{title}</text><text>{body}</text></binding></visual></toast>")
$toast = New-Object Windows.UI.Notifications.ToastNotification($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("天创呀.灵动岛同步").Show($toast)
'''
    try:
        subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                       capture_output=True, timeout=20)
    except Exception as e:
        log(f"toast 失败: {e}")


def main():
    cfg = load_config()
    interval = int(cfg.get("interval", 10))
    last_seen = STATE_PATH.read_text(encoding="utf-8").strip() if STATE_PATH.exists() else None
    log(f"灵动岛接收端启动 · 轮询 {interval}s · {cfg['gitee_owner']}/{cfg['gitee_repo']}")
    toast("灵动岛接收端已启动", f"由 是天创呀 制作 · 轮询 {interval}s", "system")

    while True:
        try:
            last_id, notifs, clipboard = fetch_state(cfg)
            if last_id and last_id != last_seen:
                if last_seen is not None:  # 首次启动不轰炸历史通知
                    latest = next((n for n in notifs if n["id"] == last_id), notifs[-1] if notifs else None)
                    if latest:
                        app = latest.get("app", "app")
                        toast(f"{latest.get('title', app)}", latest.get("text", ""), app)
                        log(f"新通知: [{app}] {latest.get('title')} {latest.get('text', '')[:40]}")
                last_seen = last_id
                STATE_PATH.write_text(last_id, encoding="utf-8")
            # 手机剪贴板 → 电脑剪贴板
            if clipboard and cfg.get("clipboard_sync", True):
                cb_file = STATE_PATH.parent / ".clip_ts"
                seen_ts = int(cb_file.read_text()) if cb_file.exists() else 0
                if int(clipboard.get("ts", 0)) > seen_ts and clipboard.get("from") == "phone":
                    ctypes.windll.user32.OpenClipboard(0)
                    ctypes.windll.user32.EmptyClipboard()
                    handle = ctypes.windll.kernel32.GlobalAlloc(0x2000, len(clipboard["text"].encode("utf-16-le")) + 2)
                    ptr = ctypes.windll.kernel32.GlobalLock(handle)
                    ctypes.cdll.msvcrt.memcpy(ptr, clipboard["text"].encode("utf-16-le"), len(clipboard["text"].encode("utf-16-le")))
                    ctypes.windll.kernel32.GlobalUnlock(handle)
                    ctypes.windll.user32.SetClipboardData(13, handle)  # CF_UNICODETEXT
                    ctypes.windll.user32.CloseClipboard()
                    cb_file.write_text(str(clipboard["ts"]))
                    log("手机剪贴板已同步到电脑")
        except Exception as e:
            log(f"轮询出错: {e}")
        time.sleep(interval)


if __name__ == "__main__":
    main()
