# Ubuntu GNOME 液态玻璃美化教程

> 本文记录这台电脑当前实际使用的方案。环境为 **Ubuntu 24.04 / GNOME Shell 46**。教程从零开始，涵盖主题、图标、鼠标、Dock、顶部栏、系统窗口、Nautilus 随机图片背景、快捷设置液态玻璃，以及本机定制的鼠标动态折射。

## 1. 最终效果与设计原则

- Dock 位于底部，呈长圆角透明玻璃托盘。
- 玻璃中心无固定白色或紫色填充，主要显示模糊后的后方内容。
- 边缘带细白边、折射、高光和轻微阴影。
- 右上角快捷设置、弹出菜单和应用文件夹只使用液态玻璃，不主动加载二次元图片。
- Nautilus 文件管理器主窗口使用独立的随机二次元图片背景。
- 桌面壁纸和文件管理器图片是两套独立逻辑。
- 鼠标经过 Dock 或次级玻璃界面时，鼠标附近会产生局部凸透镜折射。
- 窗口最小化、最大化、关闭按钮位于右上角，适合 Windows 使用习惯。

## 2. 开始前备份

GNOME 扩展或主题更新可能覆盖自定义内容，建议先备份：

```bash
mkdir -p "$HOME/gnome-beautify-backup"
dconf dump /org/gnome/shell/extensions/ > "$HOME/gnome-beautify-backup/extensions.ini"
dconf dump /org/gnome/desktop/interface/ > "$HOME/gnome-beautify-backup/interface.ini"
cp -a "$HOME/.config/gtk-4.0" "$HOME/gnome-beautify-backup/gtk-4.0" 2>/dev/null || true
cp -a "$HOME/.themes" "$HOME/gnome-beautify-backup/themes" 2>/dev/null || true
```

本机在以下目录还保存了施工前的专项备份与恢复脚本：

```text
~/.local/share/codex-gnome-liquid-glass/
~/.local/share/codex-gnome-liquid-glass/restore.sh
```

恢复本机原外观：

```bash
~/.local/share/codex-gnome-liquid-glass/restore.sh
```

执行恢复后建议注销并重新登录。

## 3. 安装基础工具

```bash
sudo apt update
sudo apt install gnome-tweaks gnome-shell-extension-manager \
  gnome-shell-extensions dconf-editor git sassc libglib2.0-dev-bin
```

打开“扩展管理器（Extension Manager）”，确认可搜索和安装扩展。

## 4. 需要的 GNOME 扩展

核心扩展：

1. **User Themes**：允许加载自定义 GNOME Shell 主题。
2. **Blur My Shell**：为 Dock、窗口、弹出菜单、应用文件夹添加模糊和自定义渲染管线。
3. **Ubuntu Dock / Dash to Dock**：管理底部 Dock。

当前机器还启用了以下装饰或效率扩展，可按需安装，不是液态玻璃的必需项：

- Caffeine
- Vitals
- Clipboard Indicator
- Coverflow Alt-Tab
- Compiz Windows Effect
- Compiz alike Magic Lamp Effect
- Rounded Window Corners
- Desktop Icons NG（DING）
- AppIndicator

安装后可运行：

```bash
gnome-extensions list --enabled
```

确认至少存在：

```text
blur-my-shell@aunetx
user-theme@gnome-shell-extensions.gcampax.github.com
ubuntu-dock@ubuntu.com
```

## 5. GTK、Shell、图标和鼠标主题

当前组合为：

```text
GTK 主题：WhiteSur-Dark
GNOME Shell：LiquidGlassTransparent
图标主题：AnimeApps
鼠标主题：nier_cursors
```

通常将下载的内容分别放入：

```text
GTK/Shell 主题：~/.themes/
图标主题：~/.local/share/icons/ 或 ~/.icons/
鼠标主题：~/.local/share/icons/ 或 ~/.icons/
```

应用主题：

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'AnimeApps'
gsettings set org.gnome.desktop.interface cursor-theme 'nier_cursors'
gsettings set org.gnome.shell.extensions.user-theme name 'LiquidGlassTransparent'
```

将窗口按钮放到右侧：

```bash
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 6. 配置底部 Dock

```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 44
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false
```

这里把 Ubuntu Dock 自带底色设为完全透明，真正的玻璃背景交给 Blur My Shell 和自定义 Shader 绘制，避免出现“一个圆角玻璃嵌在一个矩形底板里”的残边。

本机 Shell CSS 还显式清除了 Dock 原底板：

```css
#dashtodockContainer #dash,
#dashtodockContainer #dash .dash-background {
  background-color: transparent !important;
  background-image: none !important;
  border-radius: 28px !important;
  border: none !important;
  box-shadow: none !important;
}
```

实际文件位于：

```text
~/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css
```

## 7. 液态玻璃渲染管线

本机创建了三套管线：

| 管线                   | 用途            | 关键参数                       |
| -------------------- | ------------- | -------------------------- |
| `liquid_glass_dock`  | 底部 Dock       | blur 6、圆角 28、折射 0.28       |
| `liquid_glass_apps`  | Nautilus、系统设置 | blur 3、圆角 24、折射 0.24       |
| `liquid_glass_popup` | 快捷设置和次级菜单     | blur 6、圆角 24、折射 0.27、无中心色调 |

配置脚本：

```text
~/.local/share/codex-gnome-liquid-glass/configure-liquid-glass-pipeline.js
```

重新生成管线：

```bash
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
  "$HOME/.local/share/codex-gnome-liquid-glass/configure-liquid-glass-pipeline.js"
```

绑定管线：

```bash
export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"

gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock pipeline 'liquid_glass_dock'
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock override-background true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock corner-radius 32

gsettings set org.gnome.shell.extensions.blur-my-shell.applications pipeline 'liquid_glass_apps'
gsettings set org.gnome.shell.extensions.blur-my-shell.applications blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.applications static-blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.applications enable-all false
gsettings set org.gnome.shell.extensions.blur-my-shell.applications whitelist "['org.gnome.Nautilus', 'gnome-control-center', 'org.gnome.Settings']"

gsettings set org.gnome.shell.extensions.blur-my-shell.popup pipeline 'liquid_glass_popup'
gsettings set org.gnome.shell.extensions.blur-my-shell.popup blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.popup static-blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.popup override-background true
gsettings set org.gnome.shell.extensions.blur-my-shell.popup preserve-shell-theme false
gsettings set org.gnome.shell.extensions.blur-my-shell.popup quick-settings-corner-radius 24
```

应用文件夹设置：

```bash
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder blur true
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder customize true
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder sigma 18
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder brightness 0.88
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder color '(0.0, 0.0, 0.0, 0.0)'
```

## 8. 快捷设置与次级界面

右上角电量/网络点击后的面板不能直接加载二次元图片。它只采样后方桌面，经过模糊、折射和圆角裁切。

设计要点：

- `background-image: none`，禁止独立图片背景。
- `background-color: transparent`，中心无固定颜色。
- blur 不能过低，否则会像直接显示清晰壁纸；当前为 6。
- 使用 24px 圆角、细白边、顶部高光和轻阴影。
- 外层 `.popup-menu-boxpointer` 必须透明，否则会出现矩形残角。

相关 CSS 已写入：

```text
~/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css
```

## 9. 文件管理器随机二次元背景

先建立图片目录：

```bash
mkdir -p "$HOME/壁纸"
```

把 JPG、PNG 或 WebP 图片放入该目录。

本机使用两个脚本：

```text
~/.local/bin/random-anime-wallpaper   # 只切换桌面壁纸
~/.local/bin/random-app-wallpaper     # 只切换应用内部背景链接
~/.local/bin/random-nautilus          # 先随机应用背景，再打开 Nautilus
```

两套链接分别为：

```text
~/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper
~/.local/share/codex-gnome-liquid-glass/current-app-wallpaper
```

GTK 4 CSS 只对 Nautilus 加图片：

```css
window.nautilus-window,
window.background.nautilus-window {
  background-image: url("file:///home/tianchuangya/.local/share/codex-gnome-liquid-glass/current-app-wallpaper");
  background-size: cover;
  background-position: center;
}
```

文件位置：

```text
~/.config/gtk-4.0/gtk.css
```

重点：不要把 `background-image` 写到全局 `window.background`，否则系统设置、次级窗口和其他 GTK 4 软件都会错误加载二次元图片。

手动测试：

```bash
~/.local/bin/random-app-wallpaper
~/.local/bin/random-nautilus
```

要做到“每次打开文件管理器换一张”，需要让 Nautilus 的桌面启动项调用 `random-nautilus`，而不是直接调用 `nautilus`。脚本会避开上一张图片。

## 10. 登录时随机桌面壁纸

自动启动文件：

```text
~/.config/autostart/random-anime-wallpaper.desktop
```

内容：

```ini
[Desktop Entry]
Type=Application
Name=随机动漫壁纸
Exec=/home/tianchuangya/.local/bin/random-anime-wallpaper
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=2
```

登录时只切换桌面壁纸，不会修改 Nautilus 当前使用的应用背景。

## 11. 可拖动壁纸悬浮球与窗帘动画

本机安装了一个自定义 GNOME Shell 扩展：

```text
~/.local/share/gnome-shell/extensions/curtain-wallpaper@local/
```

主要文件：

```text
metadata.json    # 扩展信息与 GNOME 版本
extension.js     # 悬浮球、拖动判断、换壁纸和窗帘动画
stylesheet.css   # 圆形缩略图、玻璃外圈和窗帘样式
```

### 11.1 悬浮球效果

- 悬浮球直径约 58px，当前壁纸圆形缩略图约 46px。
- 图片使用 `background-size: cover`，保持比例并裁切为圆形。
- 外圈使用透明玻璃、细白边、内侧柔光和外围泛光。
- 悬浮球可拖到主屏幕任意位置，并限制在屏幕边缘以内。
- 松开后将位置保存到：

```text
~/.config/curtain-wallpaper-position
```

下次登录会恢复上次位置。

### 11.2 点击与拖动判断

交互必须同时满足以下规则，避免悬浮球自行跟随鼠标：

1. 只有鼠标左键按下时才开始跟踪。
2. 每次 motion 事件都检查 `Clutter.ModifierType.BUTTON1_MASK`。
3. 检测到左键松开后立即终止拖动。
4. 移动距离超过 5px 视为拖动，只保存位置。
5. 移动不足 5px 视为短按，才触发壁纸切换。

关键判断：

```javascript
const state = dragEvent.get_state();
if (!(state & Clutter.ModifierType.BUTTON1_MASK)) {
  // 左键已松开：立即停止拖动
}
```

### 11.3 Coverflow 3D 换壁纸动画

短按悬浮球后的顺序（旧窗帘下落方案已停用）：

1. 悬浮球轻微下沉并缩小，模拟按压手感。
2. 当前壁纸作为整屏 3D 卡片从 `1.0` 缩小到 `0.82`，形成桌面向后退的感觉。
3. 卡片绕 Y 轴从 `0°` 翻转到 `88°`，同时轻微横向移出。
4. 卡片接近侧面、几乎不可见时调用：

```text
~/.local/bin/random-anime-wallpaper
```

5. 随机切换 `~/壁纸` 中的图片，并等待脚本执行完成。
6. 卡片替换成新壁纸，从 `-88°` 翻转回 `0°`。
7. 新壁纸从 `0.82` 等比例放大回 `1.0`，悬浮球回弹并刷新缩略图。

动画使用 Coverflow Alt-Tab 同类的中心枢轴、Y 轴旋转和 `EASE_IN/OUT_QUINT` 缓动。过渡层始终为 `reactive: false`，只负责显示，不会抢占鼠标输入。

### 11.4 防止遮挡全屏鼠标

不要使用 `Main.layoutManager.addChrome()` 添加全屏窗帘。即使 actor 设置了 `reactive: false`，Chrome 层仍可能参与 GNOME Shell 输入区域计算，造成开机后鼠标无法点击其他窗口。

正确方式是将窗帘作为纯绘制节点加入：

```javascript
Main.uiGroup.add_child(curtain);
```

同时设置：

```javascript
reactive: false,
can_focus: false
```

只有 58px 的悬浮球本身设置为 `reactive: true`，因此不会遮挡屏幕其他区域。

启用扩展：

```bash
gnome-extensions enable curtain-wallpaper@local
```

GNOME Shell 会缓存已加载的扩展 JavaScript。修改 `extension.js` 后，仅禁用再启用可能仍运行旧代码。在 X11 会话中按 `Alt+F2`，输入 `r` 并回车；Wayland 会话需要注销后重新登录。

## 12. 鼠标动态折射（本机定制功能）

这一功能不是 Blur My Shell 官方默认设置，而是修改了本机扩展源码。

修改文件：

```text
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/effects/refraction.glsl
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/components/popup/static_actor.js
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/components/dash_to_dock.js
```

实现方式：

- Shader 增加 `pointer_x`、`pointer_y` 和 `pointer_active` uniform。
- 鼠标附近创建平滑衰减的凸透镜位移，不增加颜色遮罩。
- 弹出菜单从 GNOME Shell 舞台获取指针位置。
- Dock 的图标会拦截 motion event，因此约每 24ms 读取一次全局鼠标坐标。
- Dock 只改变图标后面整条圆角玻璃托盘，图标本身不会扭曲。
- Refraction 是双 pass 渲染，因此两遍 Shader 都必须同步鼠标参数。

注意：升级或重新安装 Blur My Shell 后，这三个文件可能被覆盖。升级前应先备份，升级后需要重新合并修改。

## 13. 顶部栏与图标挤压

顶部栏保持透明时，可以在 Shell CSS 中清除底色、阴影和图标黑边：

```css
#panel {
  background-color: transparent !important;
  background-image: none !important;
  box-shadow: none !important;
}

#panel .panel-button,
#panel .panel-button StIcon {
  text-shadow: none !important;
  icon-shadow: none !important;
}
```

如果打开应用越多，顶部应用图标挤压电量和系统状态区，应减少或关闭向顶部栏添加应用图标的扩展。系统状态、电源和网络区域应优先保留；不要同时启用多个 App Menu、任务栏或窗口标题类扩展。

## 14. 重新加载与故障排查

一般不需要重启电脑。

重载 Blur My Shell：

```bash
gnome-extensions disable blur-my-shell@aunetx
sleep 2
gnome-extensions enable blur-my-shell@aunetx
```

重载 Shell 主题：

```bash
current_theme=$(gsettings get org.gnome.shell.extensions.user-theme name)
gsettings set org.gnome.shell.extensions.user-theme name ''
sleep 1
gsettings set org.gnome.shell.extensions.user-theme name "$current_theme"
```

X11 会话也可以按 `Alt+F2`，输入 `r` 后回车。Wayland 不支持这种方式，需要注销再登录。

检查扩展状态：

```bash
gnome-extensions info blur-my-shell@aunetx
```

检查日志：

```bash
journalctl --user -b --since '10 minutes ago' --no-pager | \
  grep -Ei 'gnome-shell.*(blur|shader|uniform|error|typeerror)'
```

常见问题：

1. **玻璃太白**：先降低 `tint` 和中心 CSS 的白色透明度，再降低 `gloss`；不要一味降低 blur。
2. **壁纸太清晰，像没蒙板**：提高 `blur_radius`，但保持 `tint: 0`。
3. **有圆角但四角仍有矩形残块**：清除外层 boxpointer/container 的背景、边框和阴影，只在真正的圆角内容层绘制边缘。
4. **Dock 变成黑色托盘**：检查 Ubuntu Dock 的 `background-opacity` 是否为 0，以及 Blur My Shell 是否启用。
5. **动态折射失效**：扩展更新可能覆盖本机 Shader；检查第 12 节的三个文件。
6. **主题修改没出现**：重新加载 User Themes，必要时注销再登录。

## 15. 当前本机配置速查

```text
系统：Ubuntu 24.04
桌面：GNOME Shell 46
GTK：WhiteSur-Dark
Shell：LiquidGlassTransparent
图标：AnimeApps
鼠标：nier_cursors
窗口按钮：右侧 minimize / maximize / close
壁纸目录：~/壁纸
Dock：底部、44px 图标、智能隐藏、原生底色透明
Nautilus：每次通过自定义启动脚本打开时随机应用背景
快捷设置：无图片背景、透明中心、blur 6、24px 圆角
壁纸切换：58px 可拖动悬浮球、圆形当前壁纸缩略图、窗帘下落动画
```

## 16. 悬浮球点击切换壁纸逻辑

当前悬浮球扩展位置：

```text
~/.local/share/gnome-shell/extensions/curtain-wallpaper@local
```

最终保留的是稳定优先方案：悬浮球点击后直接从 `~/壁纸` 随机选择一张图片，并立即设置为桌面壁纸。之前尝试过截图、加载遮罩、双卡片和 3D 旋转，但在当前 GNOME Shell 环境下容易卡顿或点击失效，所以已经移除。

实现要点：

1. 悬浮球仍然可以拖动，位置保存到 `~/.config/curtain-wallpaper-position`。
2. 点击悬浮球会随机选择 `~/壁纸` 下的 JPG、PNG、WebP 图片。
3. 随机时会尽量避开当前正在使用的壁纸。
4. 切换后会同步刷新悬浮球圆形缩略图。
5. 右下角的小剪贴板按钮仍然保留，用于打开剪贴板历史。

主要逻辑在 `extension.js` 的 `_pull()` 中：

```text
_chooseNextWallpaper()：从 ~/壁纸 中随机选图
_applyWallpaper()：设置 org.gnome.desktop.background
_refreshThumbnail()：刷新悬浮球缩略图
```

为什么不直接移动真实窗口层：

GNOME Shell 没有一个稳定公开接口可以安全地把真实窗口、Dock、顶栏、桌面图标全部作为 live 对象一起 3D 变形。截图平面方案视觉更接近，但当前机器上实测不流畅；所以最终改为无动画直接切换壁纸，优先保证响应快、不卡顿、不会影响鼠标操作。

---

建议在最终满意后，把以下目录整体复制到移动硬盘或云盘：

```text
~/.themes/LiquidGlassTransparent
~/.config/gtk-4.0
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx
~/.local/share/codex-gnome-liquid-glass
~/.local/bin/random-anime-wallpaper
~/.local/bin/random-app-wallpaper
~/.local/bin/random-nautilus
~/.config/autostart/random-anime-wallpaper.desktop
~/.local/share/gnome-shell/extensions/curtain-wallpaper@local
~/.config/curtain-wallpaper-position
```
