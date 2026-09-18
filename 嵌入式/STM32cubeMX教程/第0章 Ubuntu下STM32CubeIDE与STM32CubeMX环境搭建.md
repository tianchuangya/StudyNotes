# 第 0 章 · Ubuntu 下 STM32CubeIDE 与 STM32CubeMX 环境搭建

> 下一章：[第 1 章 · HAL_GPIO_WritePin 函数](<第1章 HAL_GPIO_WritePin函数.md>)

## 本章知识地图

```text
选择正确安装包
    ↓
安装 STM32CubeIDE + 调试器 USB 规则
    ↓
安装独立版 STM32CubeMX
    ↓
CubeMX 配置并生成工程
    ↓
CubeIDE 导入、编译、下载和调试
```

本章记录的是当前电脑上已经实际完成并验证过的部署，日期为 2026-09-17。

## 1. 当前环境与安装结果

| 项目 | 当前版本或位置 | 主要作用 |
| --- | --- | --- |
| 操作系统 | Ubuntu 24.04.4 LTS，x86-64 | 开发主机 |
| STM32CubeIDE | 2.2.0 | 写代码、编译和调试 |
| STM32CubeMX | 6.18.1 | 配置芯片、引脚、时钟并生成代码 |
| GNU Tools for STM32 | GCC 14.3.1 | ARM 交叉编译器 |
| STM32CubeProgrammer CLI | 2.23.0 | 下载和操作 STM32 芯片 |
| ST-LINK Server | 2.1.1 | 为调试器提供连接服务 |
| IDE 安装目录 | `/opt/st/stm32cubeide_2.2.0` | 系统级安装 |
| CubeMX 安装目录 | `~/STM32CubeMX` | 当前用户安装 |
| 默认工作区 | `~/STM32CubeIDE/workspace_2.2.0` | IDE 工程工作区 |

已经配置的启动命令：

```bash
stm32cubeide
stm32cubemx
```

也可以直接从 Ubuntu 应用菜单搜索 **STM32CubeIDE** 或 **STM32CubeMX**。

## 2. 为什么 IDE 之外还要安装 CubeMX

从 STM32CubeIDE 2.x 开始，STM32CubeMX 不再集成在 IDE 内，而是一个独立软件。

| 软件 | 负责的工作 |
| --- | --- |
| STM32CubeMX | 选择芯片或开发板，配置引脚、时钟和外设，生成初始化代码和 `.ioc` 文件 |
| STM32CubeIDE | 编辑 C/C++ 代码，编译、链接、下载和调试 |

**核心结论**：如果只是编译一个已经生成完整的工程，可以暂时不用 CubeMX；如果要新建或修改 `.ioc`、引脚、时钟或外设配置，就需要独立的 CubeMX。

官方说明：[STM32CubeIDE 2.x 新工作流](https://community.st.com/t5/stm32-mcus/stm32cubeide-2-0-0-workflow-tutorial/ta-p/160701)

## 3. Ubuntu 为什么选择 Debian Linux 安装包

Ubuntu 属于 Debian 系，使用 `.deb` 和 `apt/dpkg` 包管理系统。因此下载 STM32CubeIDE 时应选择 **Debian Linux**。

| 下载选项 | 适用系统 |
| --- | --- |
| Debian Linux | Ubuntu、Debian、Linux Mint、Pop!_OS 等 |
| RPM Linux | Fedora、RHEL、CentOS 等 |
| Generic Linux | 没有对应原生包的其他受支持发行版 |

本机下载的正确文件是：

```text
stm32cubeide_2.2.0-Lin-Deb-x86_64.sh.zip
```

`x86_64` 与 Ubuntu 中的 `amd64` 表示相同的 64 位 PC 架构。

**易错**：所谓“通用版”并不表示它在 Ubuntu 上更好。Debian 版能够使用 Ubuntu 原生包管理器安装 IDE、ST-LINK Server 和 USB 规则，管理更规范。

## 4. STM32CubeIDE 安装过程

### 4.1 解压安装包

```bash
cd "$HOME/下载"
unzip stm32cubeide_2.2.0-Lin-Deb-x86_64.sh.zip
```

解压后得到：

```text
stm32cubeide_2.2.0_29186_20260626_0934-Lin-Deb-x86_64.sh
```

### 4.2 运行 Debian 安装器

```bash
cd "$HOME/下载"
sudo bash ./stm32cubeide_2.2.0_29186_20260626_0934-Lin-Deb-x86_64.sh
```

安装过程中需要：

1. 输入 Ubuntu 登录密码；终端不显示密码字符是正常现象。
2. 阅读并接受 ST 软件许可证。
3. 建议安装并接受 SEGGER J-Link udev rules，以便以后使用 J-Link 调试器。

安装器同时安装了：

```text
stm32cubeide-2.2.0
st-stlink-server
st-stlink-udev-rules
segger-jlink-udev-rules
```

**易错**：只在安装时使用管理员权限。平时不要用 `sudo stm32cubeide` 启动 IDE，否则工作区文件可能变成 root 所有，普通用户之后无法修改。

## 5. STM32CubeMX 安装过程

下载文件：

```text
SetupSTM32CubeMX-6.18.1-Lin-x86_64.zip
```

解压后运行：

```bash
cd "$HOME/下载/SetupSTM32CubeMX-6.18.1-Lin-x86_64"
./SetupSTM32CubeMX-6.18_1
```

在图形安装向导中选择：

```text
Install for me only (recommended)
```

其余选项保持默认，并创建应用菜单快捷方式。本机最终安装到：

```text
~/STM32CubeMX
```

CubeMX 6.18.1 已自带 Java 21，因此不需要额外安装 Java。

官方说明：[STM32CubeMX 6.18.1 安装文档](https://dev.st.com/stm32cube-docs/stm32cubemx/6.18.1/en/docs/markup/CubeMX_UserManual/chapters/03_3_installing_and_running_stm32cubemx.html)

## 6. USB 调试器配置

本机已经安装并重新加载以下规则：

```text
49-stlinkv1.rules
49-stlinkv2.rules
49-stlinkv2-1.rules
49-stlinkv3.rules
99-jlink.rules
```

当前用户也已经属于 `plugdev` 组，因此正常情况下连接 ST-LINK/J-Link 后不需要用 root 权限运行 IDE。

**补充**：安装软件时不要求开发板或 ST-LINK 在身边。只有验证实际连接、下载和调试时才需要插入硬件。

以后拿到硬件后可先检查：

```bash
lsusb
```

如果规则刚更新而设备之前已经插着，拔出再重新插入一次。

## 7. 把 IDE 改成白色主题

在 STM32CubeIDE 中打开：

```text
Window → Preferences → General → Appearance
```

然后：

1. 将 `Theme` 设置为 `Light`。
2. 如果存在 `Color and font theme`，设置为 `Light` 或 `Default`。
3. 点击 `Apply and Close`。
4. 按提示重启 IDE。

如果 `Light` 显示异常，可以尝试 `Classic`。

如果只有代码编辑区仍然是深色，可进入：

```text
Window → Preferences → General → Editors → Text Editors
```

将背景色设为白色、前景色设为黑色。

## 8. CubeIDE 2.x 的正确工程流程

### 8.1 在 CubeMX 中创建和配置工程

1. 打开 STM32CubeMX。
2. 选择 MCU 型号或开发板。
3. 在 `Pinout & Configuration` 中配置引脚和外设。
4. 在 `Clock Configuration` 中配置时钟。
5. 打开 `Project Manager`，填写工程名称与保存位置。
6. 将 `Toolchain / IDE` 选择为 `STM32CubeIDE`。
7. 点击 `GENERATE CODE`。

### 8.2 在 CubeIDE 中导入

打开：

```text
File → STM32 Project Create/Import
    → STM32CubeMX/STM32CubeIDE Project
```

选择刚才由 CubeMX 生成的工程目录，然后完成导入。

**易错**：`File → New` 打开的 `General / C/C++ / Other` 是 Eclipse 通用向导。常规 STM32 CubeMX 工程不要在这里创建，应取消该窗口并使用 `STM32 Project Create/Import`。

### 8.3 后续修改

```text
CubeMX 修改 .ioc 并重新生成代码
                 ↓
CubeIDE 刷新工程（F5）
                 ↓
重新编译
```

将自己的代码写在 CubeMX 保留区域中，例如：

```c
/* USER CODE BEGIN 2 */
/* 自己的代码 */
/* USER CODE END 2 */
```

否则重新生成代码时，写在自动生成区域中的内容可能被覆盖。

## 9. 已完成的验收

- IDE 软件包及依赖状态正常。
- CubeIDE 无界面启动测试返回产品版本 `2.2.0`。
- CubeMX 脚本模式启动、加载插件并正常退出。
- GCC 14.3.1 和 STM32CubeProgrammer 2.23.0 可以运行。
- ST-LINK/J-Link 的 5 条 udev 规则语法检查通过。
- 两个应用菜单入口及终端启动命令均可用。
- 由于当前没有连接调试器，尚未做实际烧录和调试测试。

## 本章速记

1. Ubuntu 下载 **Debian Linux** 版，不选 RPM。
2. CubeIDE 2.x 与 CubeMX 是两个独立软件。
3. CubeMX 负责配置与生成，CubeIDE 负责编码、编译和调试。
4. 安装软件时不需要插开发板；实际烧录时才需要。
5. 普通使用时不要用 `sudo` 启动 IDE 或 CubeMX。

## 参考资料

- [ST：STM32CubeIDE 安装指南](https://www.st.com/resource/en/user_manual/um2563-stm32cubeide-installation-guide-stmicroelectronics.pdf)
- [ST：STM32CubeIDE 2.x 新工作流](https://community.st.com/t5/stm32-mcus/stm32cubeide-2-0-0-workflow-tutorial/ta-p/160701)
- [ST：STM32CubeMX 6.18.1 安装与运行](https://dev.st.com/stm32cube-docs/stm32cubemx/6.18.1/en/docs/markup/CubeMX_UserManual/chapters/03_3_installing_and_running_stm32cubemx.html)
