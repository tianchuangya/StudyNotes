# Python 文件读写指南

# Python 文件读写操作指南

## 一、文件打开模式(核心基础)

文件操作的入口是 `open()` 函数，打开模式决定操作类型：

- 'r'：只读模式(默认)，文件不存在则报错

- 'w'：写入模式，覆盖原有内容，文件不存在则创建

- 'a'：追加模式，在文件末尾添加内容，文件不存在则创建

- 'r+'：读写模式，可读取也可写入(覆盖原有内容)

- 'a+'：追加+读取模式，追加后可读取文件内容

- 'b'：二进制模式(如 'rb' / 'wb')，用于图片、视频等二进制文件

## 二、文件操作的两种方式

### 1. 手动关闭(不推荐)

需手动调用 `close()`，容易遗漏导致资源泄露：

```python
f = open("example.txt", "r", encoding="utf-8")
content = f.read()
print(content)
f.close()
```

### 2. 上下文管理器(推荐首选)

`with` 语句自动关闭文件，安全简洁：

```python
with open("example.txt", "r", encoding="utf-8") as f:
    content = f.read()
    print(content)
```

## 三、文件读写核心操作

### 1. 读取文件

- `read(size)`：读取指定字节数(size 省略则读取全部)

- `readline()`：读取一行内容(含换行符 `\n`)

- `readlines()`：读取所有行，返回列表

- `for line in f:`：逐行读取(最省内存)，line 为自定义变量

### 2. 写入文件

- `write(str)`：写入字符串(需手动加 `\n`)

- `writelines(list)`：写入字符串列表(需手动加 `\n`)

### 3. 其他常用操作

- `seek(offset[, whence])`：移动文件指针(whence=0 从头，1 当前，2 末尾)

- `tell()`：返回当前文件指针位置(字节数)

- `flush()`：立即将缓冲区内容写入文件

## 四、大文件读取的内存优化重点

### 示例对比

```python
# 不推荐:大文件易内存溢出
with open("large_file.txt", "r", encoding="utf-8") as f:
    all_content = f.read()

# 推荐:逐行读取(内存友好)
with open("large_file.txt", "r", encoding="utf-8") as f:
    for line in f:            #注意：line只是变量，迭代器默认以行返回
        print(line.strip())  # 处理单行内容
```

<font color="red" size=5 family="Monospace Font" weight=bold>
line只是变量，迭代器默认以行返回
</font>

### 逐行返回原因

Python 文件迭代器默认以 `\n` 为分隔符，每次迭代调用 `readline()` 方法。

## 五、函数/方法详细列表

| 函数/方法                                 | 参数说明                                       | 功能描述           |
| ------------------------------------- | ------------------------------------------ | -------------- |
| `open(file, mode='r', encoding=None)` | file :文件路径;<br>mode :打开模式;<br>encoding :编码 | 打开文件，返回文件对象    |
| `file.read(size=-1)`                  | size :读取字节数(默认 -1 读取全部)                    | 读取文件内容，返回字符串   |
| `file.readline(size=-1)`              | size :指定读取该行字节数                            | 读取一行内容(含 `\n`) |
| `file.readlines(hint=-1)`             | hint :预计读取行数(默认 -1 读取全部)                   | 读取所有行，返回列表     |
| `file.write(str)`                     | str :需写入的字符串                               | 写入字符串，返回字符数    |
| `file.writelines(lines)`              | lines :字符串列表/可迭代对象                         | 批量写入字符串        |
| `file.seek(offset, whence=0)`         | offset :偏移量;<br>whence :起始位置               | 移动文件指针         |
| `file.tell()`                         | 无参数                                        | 返回指针位置(字节数)    |
| `file.close()`                        | 无参数                                        | 关闭文件，释放资源      |
| `file.flush()`                        | 无参数                                        | 刷新缓冲区，立即写入     |
| `file.closed`                         | 无参数(属性)                                    | 判断文件是否关闭(布尔值)  |
| `for line in file`                    | line :自定义变量                                | 逐行读取(大文件最优)    |

## 六、关键强调

1. `open()` 需指定 `encoding='utf-8'`，避免中文乱码；

2. 优先使用 `with` 语句，无需手动关闭文件；

3. 大文件读取必须用 `for line in f:`，杜绝 `read()` / `readlines()`；

4. 写入文件需手动加 `\n`，否则内容无换行。 