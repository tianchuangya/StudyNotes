# tianchuangya GNOME Liquid Glass Rice

这是 tianchuangya 当前 Ubuntu GNOME 美化配置的一键安装包。

## 使用方法

```bash
cd ~/桌面/unbuntu美化/tianchuangya-gnome-rice
bash install.sh
```

安装完成后建议注销并重新登录一次。

## 推荐工作流

这个项目现在按“一键安装脚本 + 用户数据备份包”的方式维护，比完整系统 ISO 更容易改、也更适合换电脑。

### 1. 新系统一键恢复美化

```bash
cd ~/桌面/unbuntu美化/tianchuangya-gnome-rice
bash install.sh
```

如果是在新电脑上从远程仓库开始：

```bash
bash bootstrap.sh https://gitee.com/你的用户名/tianchuangya-gnome-rice.git
```

### 2. 从当前电脑导出最新配置到项目

每次你手动改了 GNOME 设置、扩展样式、Fcitx5、终端配置之后，可以运行：

```bash
bash export-current-config.sh
```

它会把当前机器上的主题、扩展、输入法、终端、gsettings/dconf 摘要导回项目目录。

### 3. 备份用户数据

```bash
bash backup-user-data.sh
```

默认输出到：

```text
~/桌面/unbuntu美化/user-data-backups/
```

备份会包含桌面/文档/下载/图片等常见目录，以及常用配置目录；会排除缓存、Trash、`node_modules`、构建产物等。

如果要加密备份包：

```bash
TIANCHUANGYA_BACKUP_PASSWORD='你的强密码' bash backup-user-data.sh
```

加密后会生成 `.tar.zst.enc`，普通未加密压缩包会被自动删除。

### 4. 恢复用户数据

```bash
bash restore-user-data.sh ~/桌面/unbuntu美化/user-data-backups/某个备份包.tar.zst
```

恢复加密备份：

```bash
TIANCHUANGYA_BACKUP_PASSWORD='你的强密码' bash restore-user-data.sh ~/桌面/unbuntu美化/user-data-backups/某个备份包.tar.zst.enc
```

恢复时如果目标文件已存在，会先移动到：

```text
~/.local/share/tianchuangya-gnome-rice/restore-safety/
```

不会直接粗暴覆盖。

### 5. 系统体检

```bash
bash doctor.sh
```

它会检查 GNOME 扩展、主题、Fcitx5、壁纸链接、灵动岛 Gitee 配置、Blur My Shell 状态和最近 GNOME Shell 错误。

### 6. 同步到远程仓库

```bash
bash sync-remote.sh https://gitee.com/你的用户名/tianchuangya-gnome-rice.git
```

它会初始化 git、检查脚本语法、扫描疑似 token 并本地提交，但不会自动 push。确认后手动：

```bash
git push -u origin main
```

## 包含内容

- GNOME Shell 主题：LiquidGlassTransparent
- 图标主题：AnimeApps
- 鼠标主题：nier_cursors
- Fcitx5 输入法配置和皮肤：战双帕弥什 · 21号
- 悬浮球随机壁纸切换扩展：curtain-wallpaper@local
- 灵动岛手机互通扩展：island-sync@local（通知同步 + 剪贴板互通）
- blur-my-shell 动态玻璃补丁：Dock 实时采样窗口内容，弹出层动态模糊圆角裁剪
- XFCE Terminal 背景图和终端配色
- 默认二次元壁纸：wallpapers/default-wallpaper.jpg
- 微信 Fcitx5 输入法启动项修复
- 微信 Linux 版安装检测：没有微信时先安装微信，再写入 Fcitx5 启动环境
- Ubuntu Dock 位置和透明设置
- Dynamic Music Pill 顶栏音乐显示位置设置
- YesPlayMusic 自动安装逻辑
- 悬浮球扩展应急重载脚本：`restart-curtain-wallpaper`
- 当前配置导出脚本：`export-current-config.sh`
- 用户数据备份脚本：`backup-user-data.sh`
- 用户数据恢复脚本：`restore-user-data.sh`
- 系统体检脚本：`doctor.sh`
- 新电脑引导脚本：`bootstrap.sh`
- 远程同步辅助脚本：`sync-remote.sh`
- 迁移恢复指南：`docs/迁移恢复指南.md`

## 灵动岛互通配置

一键脚本会安装并启用电脑端扩展，但不会把私人令牌写死进安装包。安装后可以在扩展设置里填 Gitee 信息，或者用环境变量一次性写入：

```bash
ISLAND_SYNC_GITEE_OWNER='你的Gitee用户名' \
ISLAND_SYNC_GITEE_REPO='你的仓库名' \
ISLAND_SYNC_GITEE_TOKEN='你的私人令牌' \
bash install.sh
```

### 灵动岛弹窗交互

当前一键包内的 `island-sync@local` 已包含桌面端 UI 修订：

- 测试弹窗/通知弹窗支持拖动，拖动顶部药丸或展开卡片标题栏即可移动。
- 位置保存到 `~/.config/island-sync-position`，重启 GNOME 后仍保持。
- 展开卡片按当前屏幕分辨率计算尺寸，不再固定写死像素；高分屏下会自动放宽，低分屏下会自动收窄。
- 长消息正文会在卡片内换行并限制高度，避免按钮跑到边框外。
- 未配置启动命令的通知不会显示“打开应用”，只保留“复制内容”和“关闭”。
- Gitee 写入接受 `200~299` 成功状态，避免 `201 Created` 被误判失败。

### 手机端应用选择

新版 APK 已放在：

```text
~/桌面/unbuntu美化/apk/island-sync-debug.apk
```

手机端现在不再只靠手写 `wechat,qq` 过滤，而是支持「管理同步应用」：

- 默认监听微信、QQ、QQ 国际版和 TIM。
- 可以从手机已安装应用列表里勾选/取消要同步到电脑的应用。
- 通知写入 Gitee 时会带上 `packageName` 和 `appLabel`，电脑端更容易识别来源。
- 电脑端 `watch-apps` 默认是 `[]`，表示接受手机端已经筛选过的通知，避免手机勾选新 App 后又被电脑端拦截。

如果手机端测试推送能到电脑，但 QQ/微信真实通知不到电脑，优先怀疑手机系统没有把通知交给
`NotificationListenerService`。新版 App 已加入 **通知监听诊断**：

- 显示通知使用权是否开启；
- 显示最近一次监听到的通知包名、标题、内容；
- 显示最近一次推送到 Gitee 的结果；
- 附带“打开应用详情/权限设置”和“打开电池优化设置”快捷入口。

小米/HyperOS 机型建议把「灵动岛同步」设置为：允许自启动、电池策略无限制、最近任务锁定，
并尝试关闭后重新打开通知使用权。

### 手机端加密配置存档

新版手机端保存配置时，会同步写入加密备份：

```text
Documents/IslandSync/island-sync-settings.enc
```

备份内容包括 Gitee 仓库参数、私人令牌和已勾选应用列表。文件使用 AES-GCM 加密，
密钥由本机 Android ID 与应用固定盐派生；因此同一台手机卸载重装后可以自动恢复，
但换手机默认不能直接解密，需要重新配置。

剪贴板策略保留“手动发送”优先：Android 10+ 对后台读取剪贴板限制很强，稳定做法是通过系统分享菜单或 App 前台按钮把指定文本发送到电脑，而不是每复制一条都自动上传。

## 统一壁纸路径

安装后会创建：

```text
~/壁纸/tianchuangya-default-wallpaper.jpg
~/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper
```

桌面背景和 XFCE Terminal 都读取同一个 `current-desktop-wallpaper` 链接。

## 说明

脚本会先备份当前相关配置到：

```text
~/.local/share/tianchuangya-gnome-rice/backups/
```

如果某些第三方扩展没有预先安装，脚本会跳过对应设置，不会中断整个安装流程。

如果悬浮球偶发点击没有反应，可以运行：

```bash
restart-curtain-wallpaper
```

它会重新加载 `curtain-wallpaper@local`，相当于只刷新这个壁纸切换按钮。

## 项目位置

当前项目统一放在：

```text
~/桌面/unbuntu美化/tianchuangya-gnome-rice
```

压缩包也放在：

```text
~/桌面/unbuntu美化/tianchuangya-gnome-rice.tar.gz
```
