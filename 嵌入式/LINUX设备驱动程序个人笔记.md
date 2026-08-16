# LINUX设备驱动程序个人笔记

> 本笔记基于《LINUX设备驱动程序(第3版)[高清PDF]》，纯个人观点请鉴别

## 第一章

### 设备驱动程序

设备驱动程序的作用：驱动程序的作用在于**提交机制**，而不是提供策略。简单来讲我们把一个管理分为两层：策略层和提供层，提供层只负责专门提供统一数据接口，策略层负责下发策略。举一个例子，一个分层的TCP/IP网络：位于下层的操作系统负责提供套接字抽象层，但是在所传输的数据上面则没有任何附加策略（只单独负责数据的传输）；而上层服务器针对传输的数据执行提供不同的服务以及相关策略。个人觉得这和模块化编程思维有点像，可以串起来理解，系统分底层设备驱动程序和上层决策这样可以针对某一个进行针对性修改，最直观的例子就是，针对系统界面UI美化，但是并不会影响底层系统，用户在使用过程中只修改UI界面而不影响底层逻辑，方便了开发者进行修改，也保护的用户系统底层不被篡改

所以针对访问硬件的内核代码时，不要给用户强加任何`特定`策略，驱动程序就应该解决硬件如何访问的问题。

### 

### 内核

内核定义：内核是操作系统最基本的部分。它是为众多应用程序提供对计算机[硬件](https://baike.baidu.com/item/%E7%A1%AC%E4%BB%B6/0?fromModule=lemma_inlink)的安全访问的一部分[软件](https://baike.baidu.com/item/%E8%BD%AF%E4%BB%B6/12053?fromModule=lemma_inlink)，这种访问是有限的，并且内核决定一个程序在什么时候对某部分硬件操作多长时间。内核的分类可分为[单内核](https://baike.baidu.com/item/%E5%8D%95%E5%86%85%E6%A0%B8/4234453?fromModule=lemma_inlink)和双内核以及[微内核](https://baike.baidu.com/item/%E5%BE%AE%E5%86%85%E6%A0%B8/3856137?fromModule=lemma_inlink)。严格地说，内核并不是[计算机系统](https://baike.baidu.com/item/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%B3%BB%E7%BB%9F/7210959?fromModule=lemma_inlink)中必要的组成部分。

内核功能划分：进程管理、内存管理、文件管理、设备控制、网络功能，如下图1-1所示

![](C:\Users\ASUS\AppData\Roaming\marktext\images\2026-08-07-19-28-25-image.png)

图1-1

### 可装载模块

Linux有一个特性：内核提供的特性可以在运行时进行拓展，这意味着我们可以在系统运行时向其内核`添加/删除`功能

模块：可在运行时添加到内核中的代码被称为模块，我们可以使用insmod程序程序将模块连接到正在运行的内核，也可以使用rmmod程序移除连接

### 设备和模块分类

linux将设备分为三类：字符设备、块设备、网络设备

字符设备：能像字节流一样被访问的设备，类似C++的文件流

块设备：一次性读写多个字符的设备

网络模块：任何网络事务都是要经过一个网络接口，即能和其他主机进行交换数据的设备

### 版本编号

对内核来说，偶数编号的内核版本（如2.6.X）是用于正式发行的稳定版本，奇数（如2.7.X）是开发过程中的一个快照，它将很快被下一开发版本更新



## 第二章

### 配置开发环境





### 链接编辑器

以VScode为例，点击左下角><的标志，选择WSL

![](C:\Users\ASUS\AppData\Roaming\marktext\images\2026-08-09-17-37-22-image.png)

VScode会自动安装拓展，等待片刻之后会自动链接系统中下载的linux系统，链接成功后左下角有对应版本信息标志

![](C:\Users\ASUS\AppData\Roaming\marktext\images\2026-08-09-17-40-16-image.png)

接下来我们创建存放内核的文件

先新建一个 `kernel`文件夹，用于专门存放内核的模块

![](C:\Users\ASUS\AppData\Roaming\marktext\images\2026-08-09-17-44-08-image.png)

之后我们未来制作的任何内核模块都在此文件夹中存放

接下来我们来尝试制作“hello word”示例 

### hello world模块

1、在你的工作目录下（如演示路径为~kernel）创建一个新文件 `hello_tianmu.c`：

```c
#include <linux/module.h>    // 所有内核模块都需要
#include <linux/kernel.h>    // 包含 printk 函数
#include <linux/init.h>      // 包含 __init 和 __exit 宏

// 模块加载时调用的函数
static int __init tianmu_init(void)
{
    printk(KERN_INFO "Hello, TianmuLinux!\n");
    return 0;  // 返回0表示加载成功
}

// 模块卸载时调用的函数
static void __exit tianmu_exit(void)
{
    printk(KERN_INFO "Goodbye, TianmuLinux!\n");
}

// 告诉内核：上面那两个函数分别是加载和卸载时要调用的
module_init(tianmu_init);
module_exit(tianmu_exit);

// 模块信息（可选，但是好习惯）
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tianchuangya");
MODULE_DESCRIPTION("TianmuLinux First Kernel Module");
```

2、在同一个目录下创建 `Makefile`（注意：文件名就是 `Makefile`，没有后缀）：

```python
# 告诉编译系统：我要编译一个叫 hello_tianmu.o 的模块
obj-m += hello_tianmu.o

# 固定写法：调用内核的编译系统来编译我们的模块
all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

3、打开终端(快捷键ctrl + ` )，进入你的代码目录，输入

```bash
make
```


