# tianchuangya 设计 UI 思路

> 适用环境：Ubuntu 24.04、GNOME Shell 46、Blur My Shell（本机定制版）。本文只记录液态玻璃的参数、含义和调节方法。

> 设计目标：以透明、无色、轻折射为核心，区分 Shell 玻璃与应用玻璃的渲染来源；在保证窗口层级正确和可用性的前提下，再加入边缘泛光、鼠标响应和二次元视觉元素。

## 1. 配置文件位置

渲染管线生成脚本：

```text
~/.local/share/codex-gnome-liquid-glass/configure-liquid-glass-pipeline.js
```

GNOME Shell 外观样式：

```text
~/.themes/LiquidGlassTransparent/gnome-shell/gnome-shell.css
```

折射 Shader：

```text
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/effects/refraction.glsl
```

鼠标动态折射控制：

```text
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/components/popup/static_actor.js
~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/components/dash_to_dock.js
```

## 2. 当前三套管线参数

### 2.1 Dock：`liquid_glass_dock`

用于屏幕底部图标后面的整条长圆角托盘。

```javascript
{
  strength: 0.28,
  blur_radius: 6,
  edge_size: 18,
  falloff: 2.8,
  corner_radius: 28,
  rim_width: 3.2,
  rgb_fringing: 0.02,
  gloss: 0.38,
  tint: 0.02,
  tint_color: [1.0, 1.0, 1.0, 1.0],
  backdrop_zoom: 1.0,
  shadow: 0.16,
  texture_repeat: 0
}
```

特点：折射和边缘高光较明显，中心只有极轻的白色调。

### 2.2 应用窗口：`liquid_glass_apps`

用于 Nautilus、GNOME 设置和控制中心。

```javascript
{
  strength: 0.24,
  blur_radius: 3,
  edge_size: 16,
  falloff: 2.6,
  corner_radius: 24,
  rim_width: 3.0,
  rgb_fringing: 0.015,
  gloss: 0.34,
  tint: 0.015,
  tint_color: [1.0, 1.0, 1.0, 1.0],
  backdrop_zoom: 1.0,
  shadow: 0.13,
  texture_repeat: 0
}
```

特点：内部模糊较低，图片和内容比 Dock 更清楚。

### 2.3 快捷设置和弹出界面：`liquid_glass_popup`

用于右上角电量/网络展开面板、次级菜单和其他 Shell 弹出层。

```javascript
{
  strength: 0.27,
  blur_radius: 6,
  edge_size: 16,
  falloff: 2.6,
  corner_radius: 24,
  rim_width: 2.2,
  rgb_fringing: 0.012,
  gloss: 0.18,
  tint: 0.0,
  tint_color: [1.0, 1.0, 1.0, 1.0],
  backdrop_zoom: 1.0,
  shadow: 0.12,
  texture_repeat: 0
}
```

特点：中心完全无色，不主动加载图片；用 blur 6 避免桌面壁纸直接清晰透出，白色只来自边缘高光和 CSS 细边框。

## 3. 参数说明

| 参数 | 作用 | 增大后的表现 | 建议范围 |
|---|---|---|---|
| `strength` | 折射位移强度 | 边缘和透镜扭曲更明显 | 0.14–0.35 |
| `blur_radius` | 背景高斯模糊 | 背景细节更模糊，不等于变白 | 2–10 |
| `edge_size` | 折射影响的边缘深度 | 折射从边缘向内部延伸更远 | 10–22 |
| `falloff` | 折射衰减曲线 | 过渡更宽、更柔和 | 2.0–3.2 |
| `corner_radius` | Shader 圆角半径 | 四角更加圆润 | 18–32 |
| `rim_width` | 边缘光带宽度 | 白边和高光变宽 | 1.2–3.5 |
| `rgb_fringing` | 色散强度 | 边缘产生轻微彩色分离 | 0–0.025 |
| `gloss` | 镜面反光强度 | 边缘更亮，也可能显得过白 | 0.08–0.40 |
| `tint` | 中心综合色调 | 增大会出现白色或指定色蒙层 | 0–0.03 |
| `tint_color` | 色调颜色 RGBA | 决定 tint 混入的颜色 | 白色为 `[1,1,1,1]` |
| `backdrop_zoom` | 背景采样缩放 | 大于 1 会产生轻微放大感 | 1.0–1.03 |
| `shadow` | 玻璃内部阴影 | 增强厚度和层次 | 0.06–0.18 |
| `texture_repeat` | 超出采样区域的处理 | 1 为镜像重复，0 为边缘约束 | 通常使用 0 |

## 4. 参数调节原则

### 中间太白

按以下顺序调整：

1. 将 `tint` 降到 `0`。
2. 降低 `gloss`，例如从 `0.30` 降到 `0.15`。
3. 降低 `rim_width`，不要先降低模糊。
4. 检查 CSS 是否存在 `rgba(255,255,255,0.1)` 以上的中心背景。

`blur_radius` 只负责模糊，不应被用来控制白色程度。

### 背景像直接贴图，没有蒙板感

- 将 `blur_radius` 从 2 提高到 5–7。
- 保持 `tint: 0`，这样只模糊、不染白。
- 将 `edge_size` 调到 14–18。
- 将 `strength` 调到 0.24–0.30。

### 边缘太弱

- 提高 `rim_width`。
- 提高 `gloss`。
- 适当提高 `strength` 和 `edge_size`。
- CSS 可以增加一条约 1px 的半透明白边，但不要给外层矩形加背景。

### 边缘太白或像霓虹灯

- 优先降低 `gloss`。
- 再降低 `rim_width`。
- 将 `rgb_fringing` 控制在 0.015 以下。

### 圆角外还有矩形残块

这通常不是 `corner_radius` 参数的问题，而是外层容器仍有背景。需要清除：

```css
.popup-menu-boxpointer {
  -arrow-background-color: transparent !important;
  -arrow-border-color: transparent !important;
  background-color: transparent !important;
  box-shadow: none !important;
}
```

只在真正的 `.quick-settings` 或 `.dash-background` 上绘制圆角、边缘和阴影。

## 5. 快捷设置 CSS 参数

当前右上角面板使用：

```css
.quick-settings,
.quick-settings.popup-menu-content {
  background-color: transparent !important;
  background-image: none !important;
  border-radius: 24px !important;
  border: 1px solid rgba(255, 255, 255, 0.24) !important;
  border-top-color: rgba(255, 255, 255, 0.42) !important;
  border-left-color: rgba(255, 255, 255, 0.32) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 8px 24px rgba(0, 0, 0, 0.14) !important;
}
```

如果觉得白边太亮，可将三个边框透明度分别降到 `0.16`、`0.28`、`0.22`。

未启用的快捷开关中心接近透明：

```css
.quick-toggle:not(:checked) {
  background-color: rgba(255, 255, 255, 0.01) !important;
}

.quick-toggle:not(:checked):hover {
  background-color: rgba(255, 255, 255, 0.04) !important;
}
```

## 6. 鼠标动态折射参数

Shader 使用以下额外 uniform：

```glsl
uniform float pointer_x;
uniform float pointer_y;
uniform float pointer_active;
```

- `pointer_x`：鼠标在玻璃内的横向位置，范围 0–1。
- `pointer_y`：鼠标在玻璃内的纵向位置，范围 0–1。
- `pointer_active`：1 表示鼠标位于玻璃内，0 表示离开。

当前局部透镜核心参数：

```glsl
float pointerRadius = clamp(shortestSide * 0.28, 52.0, 120.0);
vec2 pointerDispPx = -pointerDelta * 0.075 * pointerMask;
```

调节方法：

| 目标 | 修改方式 |
|---|---|
| 扩大鼠标影响区域 | 增大 `0.28` 或最大半径 `120.0` |
| 缩小影响区域 | 降低 `0.28` 或最大半径 |
| 增强鼠标折射 | 将 `0.075` 提高到 0.09–0.12 |
| 减弱鼠标折射 | 将 `0.075` 降到 0.04–0.06 |

Dock 每 24ms 读取一次鼠标位置，约为 42 FPS：

```javascript
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 24, () => { ... });
```

如果想降低资源占用，可改为 33ms（约 30 FPS）；想更流畅可改为 16ms（约 60 FPS）。

## 7. 应用与重载

修改管线脚本后运行：

```bash
export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas"
"$HOME/.local/share/codex-gnome-liquid-glass/configure-liquid-glass-pipeline.js"

gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock pipeline 'liquid_glass_dock'
gsettings set org.gnome.shell.extensions.blur-my-shell.applications pipeline 'liquid_glass_apps'
gsettings set org.gnome.shell.extensions.blur-my-shell.popup pipeline 'liquid_glass_popup'
```

重载扩展：

```bash
gnome-extensions disable blur-my-shell@aunetx
sleep 2
gnome-extensions enable blur-my-shell@aunetx
```

重载 Shell 主题：

```bash
active_theme=$(gsettings get org.gnome.shell.extensions.user-theme name)
gsettings set org.gnome.shell.extensions.user-theme name ''
sleep 1
gsettings set org.gnome.shell.extensions.user-theme name "$active_theme"
```

一般不需要重启电脑；如果 GNOME Shell 缓存或扩展状态异常，注销并重新登录即可。

## 8. 推荐预设

### 极致透明

```text
blur_radius: 3
tint: 0
gloss: 0.12
rim_width: 1.5
strength: 0.22
```

### 当前均衡液态玻璃

```text
blur_radius: 6
tint: 0
gloss: 0.18
rim_width: 2.2
strength: 0.27
```

### 强烈玻璃边缘

```text
blur_radius: 7
tint: 0.01
gloss: 0.34
rim_width: 3.0
strength: 0.32
rgb_fringing: 0.018
```

建议每次只调整一个参数，然后重新展开面板观察；同时修改多个参数很难判断白色、模糊或折射究竟来自哪一层。

## 9. 窗口层级与玻璃采样原则

### 9.1 问题现象

部分普通应用启用 Blur My Shell 的静态应用模糊后，即使桌面已经被其他窗口遮挡，应用透明区域仍然显示桌面壁纸。原因是这类背景 actor 采样或复制了桌面背景，而不是实时采样应用窗口后方的完整合成场景。

这会破坏空间关系：视觉上像应用窗口在所有其他窗口上打了一个“直通桌面的洞”。

### 9.2 分层解决方案

- **Dock 与快捷设置**：必须使用 Blur My Shell 的动态模糊（`static-blur=false`），直接读取当前合成场景；不能创建装有桌面壁纸的 `Meta.BackgroundActor` 再裁切到 UI 中。
- **边缘玻璃感**：动态路径负责真实背景模糊，圆角、细白边、内高光和外泛光由 Shell CSS 负责。
- **普通应用**：Nautilus 以外的 GTK/libadwaita 窗口使用应用自身拟态玻璃，不再使用桌面背景副本。
- **Nautilus**：保留明确限定在 `window.nautilus-window` 上的随机二次元应用背景。
- **禁止全局图片**：绝不将二次元 `background-image` 写入全局 `window.background`。

当前已关闭普通应用的 Blur My Shell 背景采样：

```bash
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
gsettings set org.gnome.shell.extensions.blur-my-shell.applications blur false
```

Dock 与快捷设置当前也已禁止静态壁纸副本：

```bash
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur false

GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
gsettings set org.gnome.shell.extensions.blur-my-shell.popup static-blur false
```

重要限制：本机 GNOME 46 的 `Shell.BlurEffect` 没有 `corner-radius` 属性。动态背景模糊虽然能采样真实合成画面，但模糊层只能保持矩形，CSS 圆角无法裁掉它的四角；它也不会把实时画面纹理交给自定义 GLSL Shader。因此“真实后方画面、动态自定义折射、干净圆角”在当前接口上不能同时成立。此前鼠标折射看似更强，是因为 Shader 处理的是强行放入 UI 的桌面壁纸副本，这会产生错误的空间关系。

最终选择空间关系和轮廓正确：Dock 与弹出面板关闭 Blur My Shell 模糊层，使用清晰透明中心以及 Shell CSS 绘制的圆角、白边、内高光和泛光：

```bash
GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur false

GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas" \
gsettings set org.gnome.shell.extensions.blur-my-shell.popup blur false
```

## 10. 纯 CSS 拟态玻璃灵感

灵感来源：[greyd097/yzrt 纯 CSS 液态玻璃](https://gitee.com/greyd097/yzrt/tree/master/)。该方案没有依赖 WebGL 或 SVG 位移滤镜，而是通过基础 CSS 在相似度和性能之间折中。

可迁移的视觉层：

1. `rgba(255,255,255,0.04)` 一类的极低中心填充。
2. 多层 `inset box-shadow`，同时模拟亮边、暗边和玻璃厚度。
3. 45° 对角渐变，模拟光线掠过玻璃表面。
4. 模糊的深色内轮廓，模拟边缘折射阴影。
5. 细白色内圈与外部柔光，使玻璃在明暗壁纸上都可辨认。

浏览器方案里的 `backdrop-filter`、伪元素和嵌套 CSS 不能原样用于 GNOME Shell。实际移植使用 GTK CSS、StTheme CSS 和现有 refraction Shader 分工完成。

![应用拟态玻璃分层参考](/home/tianchuangya/桌面/tianchuangya-UI参考图/拟态玻璃分层.svg)

当前 GTK 普通窗口采用的核心思路：

```css
window.background {
  background-color: rgba(10, 14, 22, 0.46);
  background-image: linear-gradient(135deg,
                    rgba(255,255,255,0.14),
                    rgba(255,255,255,0.025) 28%,
                    rgba(0,0,0,0.06) 72%,
                    rgba(255,255,255,0.10));
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.24),
              inset 2px -2px 2px rgba(255,255,255,0.22),
              inset -2px 2px 2px rgba(255,255,255,0.13);
}
```

## 11. Uiverse 交互动画移植思路

参考代码使用按钮主体、上下抽屉、四角装饰、悬停放大、按压缩小、阴影和色相动画，原始曲线为带明显回弹的 cubic-bezier。

GNOME Shell 不支持直接复制以下浏览器能力：

- `:has()`、`::before`、`::after`
- CSS 自定义变量与复杂 `calc()`
- `filter: drop-shadow()` 和 `hue-rotate()`
- WebKit 专用文本裁切
- 浏览器 `@keyframes`

移植到剪贴板条目时采取克制版本：

- 静止：透明中心、极细白边。
- 悬停：放大到 `1.015`，增强内边光和外部阴影。
- 按下：缩小到 `0.975`。
- 松开：使用 `Clutter.AnimationMode.EASE_OUT_BACK` 回弹。
- 不使用持续色相旋转，保持无色液态玻璃风格。
- 不让四角装饰超出滚动区，避免相邻条目互相覆盖。

![剪贴板交互动画参考](/home/tianchuangya/桌面/tianchuangya-UI参考图/剪贴板交互动画.svg)

核心 GJS 动画参数：

```javascript
actor.ease({
  scale_x: 1.015,
  scale_y: 1.015,
  duration: 180,
  mode: Clutter.AnimationMode.EASE_OUT_QUAD,
});

actor.ease({
  scale_x: 0.975,
  scale_y: 0.975,
  duration: 90,
  mode: Clutter.AnimationMode.EASE_OUT_QUAD,
});
```

## 12. 设计决策速查

| 场景 | 背景来源 | 中心处理 | 边缘处理 | 交互 |
|---|---|---|---|---|
| Dock | 后方画面直接透过 | 无模糊、无壁纸副本 | CSS 32px 圆角、细白边、内高光、泛光 | 清晰透明玻璃 |
| 快捷设置 | 后方画面直接透过 | 无模糊、无壁纸副本 | CSS 24px 圆角、细白边、泛光 | 清晰透明玻璃 |
| 普通 GTK 应用 | 应用自身背景 | 半透明暗底、对角渐变 | 多层 inset 高光 | 常规窗口交互 |
| Nautilus | 独立随机应用图片 | 暗色可读性遮罩 | GTK 内边光 | 每次启动换图 |
| 剪贴板条目 | Shell 弹出菜单 | 透明条目底 | 12px 圆角、悬停亮边 | 放大、按压、回弹 |

核心原则：真实折射只用于能正确取得后方画面的场景；无法正确采样窗口堆叠时，使用拟态玻璃比错误地显示桌面壁纸更可信。
