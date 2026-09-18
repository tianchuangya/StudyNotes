# Island Sync · 灵动岛手机↔电脑互通（第一版）

> **作者：是天创呀（tianchuangya）** · © 2026 保留所有权利
> 手机系统通知实时同步到电脑，以"灵动岛"药丸弹窗展示；剪贴板双向互通。
> 中转站是你自己的 Gitee 私有仓库 —— 无需公网 IP、无需自建服务器，国内直连。

## 架构

```
┌──────────┐  通知监听(NotificationListenerService)   ┌──────────────┐
│ 手机 APK │ ──── 合并 1.5s → PUT island.json ───────▶ │              │
└──────────┘                                           │  Gitee 仓库  │
                                                       │ island.json  │
┌────────────────────────────────┐                     │              │
│ 电脑 GNOME 扩展 island-sync@local │ ◀── 每 10s GET ─── │              │
│  · 顶部灵动岛药丸（可展开卡片）   │                     └──────────────┘
│  · 点击「打开微信/QQ」启动应用    │
│  · 剪贴板：手机→电脑自动；       │
│    电脑→手机在面板菜单手动推送   │
└────────────────────────────────┘
```

## 第一步 · 准备 Gitee 仓库

1. 在 Gitee 新建一个**私有**仓库（例如 `island-sync`，分支 `master`）。
2. 头像 → 设置 → 私人令牌 → 生成新令牌（勾选 `projects` 权限），复制保存。
3. 把本目录的 `island.json.example` 内容手动创建为仓库根目录的 `island.json`
   （或者直接用手机 App 的「发送测试通知」首次自动创建）。

## 第二步 · 电脑端（GNOME 扩展）

```bash
bash ~/桌面/unbuntu美化/island-sync/pc-extension/install.sh
```

装完后：扩展管理器 → Island Sync → 设置，填入：

| 字段 | 说明 |
|---|---|
| Gitee 用户名 / 仓库名 | 例如 `tianchuangya / island-sync` |
| 分支 / 文件路径 | 默认 `master` / `island.json` |
| Gitee 私人令牌 | 第一步生成的 token |
| 轮询间隔 | 默认 10 秒（越短越实时，越高耗电） |
| launch-map | 通知点击后打开应用的命令，默认 `{"wechat": "gtk-launch wechat", "qq": "gtk-launch qq"}` |

如果扩展设置界面暂时没出现，可以直接用命令写入配置：

```bash
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/island-sync@local/schemas"
GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR" gsettings set org.gnome.shell.extensions.island-sync gitee-owner '你的Gitee用户名'
GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR" gsettings set org.gnome.shell.extensions.island-sync gitee-repo '你的仓库名'
GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR" gsettings set org.gnome.shell.extensions.island-sync gitee-token '你的私人令牌'
GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR" gsettings set org.gnome.shell.extensions.island-sync gitee-branch 'master'
GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR" gsettings set org.gnome.shell.extensions.island-sync gitee-path 'island.json'
```

修改扩展文件后，推荐按 `Alt+F2 → r → 回车` 重新加载 GNOME Shell。不要手动运行
`gnome-shell --replace`，那样容易把桌面会话环境搞乱。

装好后顶部面板出现手机图标菜单：立即同步 / 显示测试灵动岛 / 推送剪贴板到手机 / 上次同步状态。

「显示测试灵动岛」不依赖手机和 Gitee，用来先检查电脑端 UI 是否能正常弹出、展开和点击。

通知到达时屏幕顶部居中弹出玻璃药丸（应用 + 标题 + 摘要），点击展开卡片：
**打开微信 / 打开QQ / 复制内容 / 关闭**。

## 第三步 · 手机端（APK 构建）

`phone-android/` 是完整的 Android Studio 工程（Kotlin，无第三方依赖）：

Codex 已经构建好的 debug APK 放在：

```text
~/桌面/unbuntu美化/apk/island-sync-debug.apk
```

可以直接把这个 APK 发到手机安装。

1. Android Studio → Open 打开 `phone-android/`，等 Gradle 同步完成；
2. `Build → Build APK(s)` 生成 `app/build/outputs/apk/debug/app-debug.apk`；
3. 安装到手机，打开 App：
   - 填写 Gitee 用户名 / 仓库名 / 令牌 → 保存；
   - 保存时会自动生成加密配置备份；
   - 点 **① 授权读取系统通知**（设置里允许「灵动岛同步」）；
   - 点 **② 启动常驻后台服务**（前台服务 + 开机自启，建议在最近任务里锁 定）；
   - 点 **管理同步应用**，从手机已安装应用里勾选要同步到电脑的应用；
   - 点 **③ 发送测试通知** —— 电脑几秒内应弹出灵动岛。

默认会监听微信、QQ、QQ 国际版和 TIM；后续要测试其他 App，不需要改代码，直接在
「管理同步应用」里勾选即可。通知同步仍保留 1.5 秒合并，避免连发刷屏。

### 加密配置存档

手机端会把关键配置另存为加密存档：

```text
Documents/IslandSync/island-sync-settings.enc
```

包含内容：

- Gitee owner/repo/branch/path；
- Gitee 私人令牌；
- 已勾选的同步应用包名列表。

存档使用 AES-GCM 加密，不是明文。密钥由这台手机的 Android ID 与应用固定盐派生：

- 覆盖安装升级：App 私有配置本身会保留，同时也会更新加密存档。
- 卸载后重装：只要公共 Documents 里的存档还在，打开 App 时会自动恢复配置。
- 换手机：默认不能直接解密旧手机存档，需要重新填写配置。

App 里也提供了两个手动按钮：

- **备份配置到加密存档**
- **从加密存档恢复配置**

### QQ 不同步时先查这几项

1. 手机设置里确认已经允许「灵动岛同步」的 **通知使用权**。
2. 手机打开「灵动岛同步」App，点 **管理同步应用**，确认 QQ/TIM 对应条目已勾选。
3. 点 **② 启动常驻后台服务**，并在最近任务里锁定本应用，避免系统后台清理。
4. 点 **通知监听诊断**，查看最近一次系统通知是否被 App 监听到。
5. 电脑端顶栏手机图标菜单里点「立即同步」，看状态是否显示同步失败。
6. 如果手机端「发送测试通知」能到电脑，而 QQ 不能到电脑，基本就是通知使用权、QQ 包名未勾选或系统后台限制。

小米/HyperOS 机型建议额外设置：

- 应用详情里允许自启动；
- 电池策略改为无限制；
- 最近任务里锁定「灵动岛同步」；
- 通知使用权如果已打开但仍无效，可以关闭后重新打开一次；
- 如果诊断页里“通知使用权已开启”，但发 QQ/微信后“最近监听记录”完全不变，说明系统没有把通知交给本 App。

App 内新增三个排障按钮：

- **通知监听诊断**：显示通知使用权、最近监听到的包名/标题/内容、最近推送结果。
- **打开应用详情/权限设置**：快速跳到本 App 权限页。
- **打开电池优化设置**：快速检查后台/省电限制。

### 剪贴板互通

* **手机 → 电脑**：手机上复制内容后，从分享菜单选「灵动岛同步」；电脑端轮询到
  `clipboard.from=phone` 的新条目后自动写入电脑剪贴板并通知。
  （Android 10+ 禁止后台读剪贴板，所以走系统分享入口，这是官方限制。）
* **电脑 → 手机**：面板菜单「推送剪贴板到手机」，手机端下次拉取即可在
  App 里看到/复制（后续版本可在通知里加"复制"操作按钮）。

> 设计备注：手机后台“每复制一条就自动偷读并询问是否发送”在 Android 10+ 上不稳定，
> 系统会限制后台剪贴板访问。稳定方案是保留分享入口，并在 App 前台/快捷操作里做“发送到电脑”。
> 后续可以把电脑端剪贴板历史 UI 增加一个“手机剪贴板”分区，不再每条都自动写进电脑剪贴板。

## 已知限制与后续计划

* 大文件（>100MB）传输：第一版只做通知+文本剪贴板。图片等小文件可走
  Gitee 附件或 issue 评论区；大文件建议后续换 SFTP/WebDAV 直连或局域网 mDNS 方案。
* 实时性受轮询间隔限制（Gitee 无推送回调）；把电脑端轮询调到 5s 已经接近即时。
* 微信 PC 端启动命令因安装方式而异：官方 deb 桌面项通常可用 `gtk-launch wechat`，
  Flatpak 可改成 `flatpak run com.tencent.WeChat`，可在 launch-map 里自行调整。
* 手机端 JSON 写入是"读-改-写"，两台设备同时写可能冲突，App 内置了 2s 重试。

## 2026-09-02 桌面端 UI 修订

这版针对测试弹窗做了几项实用修复：

* 灵动岛药丸和展开卡片可以拖动；拖药丸或卡片标题栏即可移动，位置保存到 `~/.config/island-sync-position`。
* 卡片宽高不再写死绝对像素，而是按当前主屏幕尺寸映射：卡片宽度约为屏幕宽度的 30%～42%，高度约为屏幕高度的 40%～54%。
* 通知正文支持自动换行和高度限制，长文本会在卡片内裁切，不再把按钮顶出边框。
* “打开应用”按钮只在 `launch-map` 里确实配置了该 app 的启动命令时显示；普通文本/未知来源通知只显示“复制内容/关闭”。
* 按钮加了最小宽度和更宽的卡片布局，避免“打开微信”这类文字被省略号截断。
* Gitee 写入成功判断从只认 `200 OK` 改为接受所有 `2xx`，避免 `201 Created` 被误判为失败。
* 手机端新增「管理同步应用」：读取手机已安装应用列表，按包名勾选同步范围，默认微信/QQ/TIM。

## 文件结构

```
island-sync/
├── pc-extension/            # 电脑端 GNOME 扩展
│   ├── island-sync@local/   #   扩展本体（extension.js + schema + 样式）
│   └── install.sh
├── phone-android/           # 手机端 Android Studio 工程（Kotlin）
├── island.json.example      # Gitee 仓库数据文件格式
└── README.md
```


## 远程更新（v1.1 新增）

手机 App 支持通过 GitHub 仓库远程更新：

```
电脑:  island-sync/release/publish-update.sh --notes "说明"
       （自动：构建 → SHA256 → GitHub Release 上传 APK → 提交 update.json）
手机:  App → 填 update.json 直链 → 「检查 App 更新」→ 下载+校验+系统确认安装
       （App 启动时也会静默检查，有新版本才弹窗）
```

配置步骤见 `release/README-发布配置.md`（建仓库 → Fine-grained token → 填
publish.conf，约 5 分钟）。安全机制：APK 经 SHA256 校验，篡改包会被丢弃；
安装走系统确认框，无需 root。
