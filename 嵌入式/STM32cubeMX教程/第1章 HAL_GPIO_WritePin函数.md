# 第 1 章 · `HAL_GPIO_WritePin()` 函数

> 上一章：[第 0 章 · Ubuntu 下 STM32CubeIDE 与 STM32CubeMX 环境搭建](<第0章 Ubuntu下STM32CubeIDE与STM32CubeMX环境搭建.md>)

## 本章知识地图

```text
物理引脚 PF9
    ↓ 拆成“端口 + 端口内编号”
GPIOF + GPIO_PIN_9
    ↓ CubeMX 用户标签生成宏
L1_GPIO_Port + L1_Pin
    ↓ 传入 HAL 函数
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET)
```

**适用范围**：本章针对当前工程和教学视频中使用的经典 STM32Cube HAL GPIO API。少数采用新版 HAL2 的芯片系列可能使用不同类型或名称，应以工程自动生成的头文件为准。

## 1. 函数的作用与原型

`HAL_GPIO_WritePin()` 用于设置或清除一个 GPIO 输出引脚，也就是让它输出高电平或低电平。

```c
void HAL_GPIO_WritePin(GPIO_TypeDef *GPIOx,
                       uint16_t GPIO_Pin,
                       GPIO_PinState PinState);
```

该函数没有返回值，三个参数依次回答三个问题：

```text
操作哪一个端口？ → 操作端口中的哪一位？ → 写入什么电平？
```

## 2. 三个参数

| 参数 | 类型 | 含义 | PF9 示例 |
| --- | --- | --- | --- |
| `GPIOx` | `GPIO_TypeDef *` | 选择 GPIO 端口 | `GPIOF` |
| `GPIO_Pin` | `uint16_t` | 选择该端口内的引脚位 | `GPIO_PIN_9` |
| `PinState` | `GPIO_PinState` | 指定输出状态 | `GPIO_PIN_SET` 或 `GPIO_PIN_RESET` |

完整示例：

```c
HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET);
```

含义是：让 `PF9` 输出高电平。

**补充**：`GPIOF` 不是字符 `F`，而是由芯片头文件定义、指向 GPIOF 硬件寄存器组的地址。初学阶段把它理解为“选择 F 端口”即可。

## 3. 为什么写 `GPIO_PIN_9`，而不是直接写 `PF9`

STM32 的 GPIO 引脚名称由两部分组成：

```text
PF9
│└── 9：F 端口中的第 9 号引脚 → GPIO_PIN_9
└─── F：GPIO 端口 F            → GPIOF
```

因此：

```text
PF9 = GPIOF + GPIO_PIN_9
```

HAL 函数把这两部分设计成两个参数：

```c
HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET);
```

同一个 `GPIO_PIN_9` 与不同端口组合，会表示不同的物理引脚：

| 函数前两个参数 | 对应物理引脚 |
| --- | --- |
| `GPIOA, GPIO_PIN_9` | PA9 |
| `GPIOB, GPIO_PIN_9` | PB9 |
| `GPIOF, GPIO_PIN_9` | PF9 |

**易错**：`GPIO_PIN_9` 本身只表示“端口内第 9 位”，它并没有说明是 A、B 还是 F 端口。

## 4. 第二个参数实际是位掩码

`GPIO_PIN_9` 不是普通整数 `9`，而是一个只有第 9 位为 1 的位掩码。HAL 头文件中的定义类似：

```c
#define GPIO_PIN_9  ((uint16_t)0x0200U)
#define GPIO_PIN_10 ((uint16_t)0x0400U)
```

这使函数可以一次操作同一端口内的多个引脚：

```c
HAL_GPIO_WritePin(GPIOF,
                  GPIO_PIN_9 | GPIO_PIN_10,
                  GPIO_PIN_SET);
```

这句会同时让 PF9 和 PF10 输出高电平。

**限制条件**：一次调用只有一个端口参数，所以只有属于同一端口的引脚才能这样组合。不同端口必须分开调用。

## 5. CubeMX 用户标签与宏映射

假设在 CubeMX 中进行了如下配置：

| 物理引脚 | GPIO 模式 | User Label |
| --- | --- | --- |
| PF9 | `GPIO_Output` | `L1` |
| PF10 | `GPIO_Output` | `L2` |

生成代码后，`Core/Inc/main.h` 中通常会出现：

```c
#define L1_Pin       GPIO_PIN_9
#define L1_GPIO_Port GPIOF

#define L2_Pin       GPIO_PIN_10
#define L2_GPIO_Port GPIOF
```

因此下面两种写法完全等价：

```c
HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET);
```

```c
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET);
```

### 5.1 教学视频为什么看起来像“直接映射变量”

视频中的代码：

```c
HAL_GPIO_WritePin(LED_RED_GPIO_Port,
                  LED_RED_Pin,
                  GPIO_PIN_SET);
```

`LED_RED_GPIO_Port` 和 `LED_RED_Pin` 通常不是运行时变量，而是 CubeMX 根据 `LED_RED` 用户标签生成的预处理宏：

```c
#define LED_RED_GPIO_Port GPIOF
#define LED_RED_Pin       GPIO_PIN_9
```

C 预处理器会在编译前进行文本替换：

```text
HAL_GPIO_WritePin(LED_RED_GPIO_Port, LED_RED_Pin, GPIO_PIN_SET)
                              ↓ 宏展开
HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET)
```

**纠错**：这不是把整个 GPIO 映射到一个普通变量，而是分别给“端口”和“引脚位掩码”起了更容易理解的宏名称。

### 5.2 为什么推荐使用标签宏

```c
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET);
```

比下面的硬编码更容易理解：

```c
HAL_GPIO_WritePin(GPIOF, GPIO_PIN_9, GPIO_PIN_SET);
```

使用标签宏的优点：

- 看到 `L1` 就知道代码操作的是哪个设备。
- 如果以后在 CubeMX 中把 L1 改接到其他引脚，重新生成代码后宏会自动更新。
- 业务代码通常不需要跟着修改。

**易错**：C 语言区分大小写。若 CubeMX 标签写的是小写 `l1`，生成的名称可能是 `l1_Pin` 和 `l1_GPIO_Port`。始终以当前工程 `main.h` 中的实际定义为准。

## 6. 第三个参数：SET 和 RESET

```c
GPIO_PIN_SET    /* 设置引脚，通常对应高电平 */
GPIO_PIN_RESET  /* 清除引脚，通常对应低电平 */
```

例如：

```c
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET);
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_RESET);
```

**易混**：`SET/RESET` 描述的是 GPIO 输出电平，不直接等于“LED 亮/灭”。

| LED 接法 | `GPIO_PIN_SET` | `GPIO_PIN_RESET` |
| --- | --- | --- |
| 高电平点亮（active-high） | 亮 | 灭 |
| 低电平点亮（active-low） | 灭 | 亮 |

因此 LED 的实际亮灭要结合开发板原理图判断。

**补充**：上表针对常见的推挽输出。若配置为开漏输出，`SET` 通常表示释放线路，最终电平还取决于外部或内部上拉。

## 7. L1、L2 交替输出示例

将代码放在 CubeMX 保留的用户代码区域：

```c
/* USER CODE BEGIN WHILE */
while (1)
{
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(L2_GPIO_Port, L2_Pin, GPIO_PIN_RESET);
    HAL_Delay(500);

    HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(L2_GPIO_Port, L2_Pin, GPIO_PIN_SET);
    HAL_Delay(500);
}
/* USER CODE END 3 */
```

`HAL_Delay(500)` 表示延时约 500 ms。如果板载 LED 是低电平点亮，观察到的亮灭顺序会与 `SET/RESET` 字面理解相反。

若只需要翻转一个引脚，也可以使用：

```c
HAL_GPIO_TogglePin(L1_GPIO_Port, L1_Pin);
HAL_Delay(500);
```

## 8. 使用前提

调用 `HAL_GPIO_WritePin()` 前，目标引脚通常需要满足：

1. 对应 GPIO 外设时钟已经开启。
2. 引脚已经配置成输出模式，例如 `GPIO_MODE_OUTPUT_PP`。
3. `MX_GPIO_Init()` 已经执行。

使用 CubeMX 将 PF9/PF10 设置为 `GPIO_Output` 并生成代码时，这些初始化通常由 `MX_GPIO_Init()` 自动完成。

**易错**：只设置 User Label 而没有把引脚配置为 GPIO 输出，不能保证 `WritePin()` 得到预期结果。

## 9. 相关 GPIO 函数对比

| 函数 | 作用 | 典型场景 |
| --- | --- | --- |
| `HAL_GPIO_WritePin()` | 明确写入高或低电平 | 打开、关闭某个输出 |
| `HAL_GPIO_TogglePin()` | 翻转当前输出状态 | LED 周期闪烁 |
| `HAL_GPIO_ReadPin()` | 读取引脚输入电平 | 按键、传感器数字输入 |

## 10. 常见错误检查表

- 把 `PF9` 直接填入第二个参数，而不是拆成 `GPIOF` 和 `GPIO_PIN_9`。
- 把 `GPIO_PIN_9` 错写成普通数字 `9`。
- 将 `L1_GPIO_Port` 和 `L2_Pin` 错误搭配。
- 忘记在 CubeMX 中设置 `GPIO_Output`。
- 误以为 `GPIO_PIN_SET` 一定代表 LED 点亮。
- 修改了 CubeMX 自动生成区域，重新生成代码后内容被覆盖。
- 标签大小写与 `main.h` 中生成的宏不一致。

## 本章自测

1. `PF9` 应拆成哪两个 HAL 参数？
2. 为什么 `GPIO_PIN_9` 不能单独确定一个物理引脚？
3. `L1_Pin` 是普通变量还是宏？
4. `GPIO_PIN_SET` 是否一定表示 LED 点亮？
5. PF9 和 PF10 能否在一次 `HAL_GPIO_WritePin()` 中同时设置？PA9 和 PF9 呢？

<details>
<summary>查看答案</summary>

1. `GPIOF` 和 `GPIO_PIN_9`。
2. 每个 GPIO 端口都可能有第 9 号引脚，还必须同时指定端口。
3. 通常是 CubeMX 在 `main.h` 中生成的预处理宏。
4. 不一定；还要看 LED 是高电平点亮还是低电平点亮。
5. PF9 和 PF10 同属 GPIOF，可以组合位掩码；PA9 和 PF9 属于不同端口，必须分开调用。

</details>

## 本章速记

```text
PF9 = GPIOF + GPIO_PIN_9
L1  = L1_GPIO_Port + L1_Pin
SET/RESET 表示输出电平，不保证等于 LED 亮/灭
```

推荐写法：

```c
HAL_GPIO_WritePin(L1_GPIO_Port, L1_Pin, GPIO_PIN_SET);
```

## 参考资料

- [ST 官方 HAL GPIO 源码：`HAL_GPIO_WritePin()`](https://github.com/STMicroelectronics/stm32f4xx-hal-driver/blob/master/Src/stm32f4xx_hal_gpio.c)
- [ST 官方 HAL GPIO 头文件：引脚位掩码与函数声明](https://github.com/STMicroelectronics/stm32f4xx-hal-driver/blob/master/Inc/stm32f4xx_hal_gpio.h)
