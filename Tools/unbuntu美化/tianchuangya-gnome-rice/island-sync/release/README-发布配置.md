# APK 远程更新 · 发布与使用指南

## 原理

```
电脑（开发者）                                手机（App）
publish-update.sh
 ├─ gradle 构建 APK
 ├─ 计算 SHA256
 ├─ GitHub Release 上传 APK 附件 ──────────▶  「检查更新」
 └─ 提交 update.json（版本/直链/摘要）  ◀── 读 update.json
                                            ├─ 对比 versionCode
                                            ├─ 下载 APK + SHA256 校验
                                            └─ PackageInstaller 系统确认安装
```

update.json 格式：

```json
{
  "versionCode": 2,
  "versionName": "1.1",
  "url": "https://github.com/<owner>/<repo>/releases/download/v1.1/island-sync-1.1.apk",
  "sha256": "…",
  "notes": "更新说明"
}
```

## 一次性配置（约 5 分钟）

1. **建仓库**：GitHub 新建仓库（如 `island-sync-updates`），建议 public
   （public 才能用 raw 直链免 token 检查更新；private 也支持，但手机端检查时要填 token）。
2. **建令牌**：https://github.com/settings/tokens → Fine-grained tokens →
   只勾选这个仓库 → Permissions 里 `Contents: Read and write`。
3. **填配置**：
   ```bash
   cd ~/桌面/unbuntu美化/island-sync/release
   cp publish.conf.example publish.conf
   # 编辑 publish.conf 填入 用户名/仓库名/令牌
   chmod +x publish-update.sh
   ```
4. **改版本号**：`phone-android/app/build.gradle.kts` 里的
   `versionCode`（+1，必须递增）和 `versionName`。

## 日常发布

```bash
cd ~/桌面/unbuntu美化/island-sync/release
./publish-update.sh --notes "修复了XX；新增了YY"
```

脚本会自动：构建 → SHA256 → 创建 Release（tag=v版本号）→ 上传 APK → 提交 update.json。

## 手机端使用

1. 打开「灵动岛同步」→ 找到 **更新源** 输入框，填：
   ```
   https://raw.githubusercontent.com/<owner>/<repo>/main/update.json
   ```
   → 点「保存配置」。
2. 点 **检查 App 更新**：
   - 有新版本 → 弹窗显示更新说明 → 「下载并安装」→ 下载（进度提示）→
     SHA256 校验 → 系统安装确认框 → 安装完成自动重启 App。
   - 首次安装会要求授予「安装未知应用」权限，按提示去系统设置允许一次即可。
3. 每次 App 启动也会静默检查，有新版本才弹窗，不会打扰。

## 常见问题

| 现象 | 原因/处理 |
|---|---|
| 检查更新一直"无法获取" | update.json 直链不通：public 仓库确认 URL 是 `raw.githubusercontent.com/.../main/update.json`；private 仓库需要 App 内 token 支持（当前版本检查更新用无鉴权直链，请用 public 仓库） |
| 发布脚本报 401 | token 无效或没给 Contents 写权限 |
| 发布脚本报 422 tag 已存在 | 同版本号已发布过：先改 build.gradle.kts 里的 versionCode/Name 再发布 |
| 安装确认框不出现 | 手机「安装未知应用」权限没开：App 内会自动跳转授权页 |
| SHA256 校验失败 | 下载不完整或 update.json 与 APK 不配套：重新发布一次 |

## 安全说明

- `publish.conf` 含令牌，**不要**提交到任何仓库/打包进压缩包（已确认在 .gitignore 习惯里）。
- update.json 的 SHA256 保证手机只安装你发布的那个 APK，被中间篡改的包会被丢弃。
