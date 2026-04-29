# C++ 按自定义分隔符分割字符串及数值转换

# C++ 基于`stringstream`按自定义分隔符分割字符串（进阶用法）

## 一、核心知识点总结

### 1. <span style="color:#ee4c2e">**【重点】核心实现逻辑**</span>

使用`std::stringstream`结合`std::getline`，通过指定**自定义分隔符**（如<span style="color:#9221ff">逗号、分号、竖线</span>）拆分字符串，核心流程如下：

1. 将待分割字符串传入`stringstream`，构建字符串流对象；

2. 循环调用`std::getline`读取流内内容，读取至指定分隔符时停止；

3. 可选过滤空字符串，用于处理<span style="color:#9221ff">连续分隔符（如`a,,b`）、首尾分隔符（如`,a,b,`）</span>的特殊场景。

### 2. <span style="color:#209fff">**核心组件与函数**</span>

- 存储容器：`std::vector<std::string>`，用于存放分割后的所有子串；

- 流载体：`std::stringstream`，将普通字符串封装为流，支持流式读写操作；

- 读取工具：`std::getline`，核心读取函数，支持自定义分隔符，是实现灵活分割的关键。

### 3. <span style="color:#32833a">**【备注】边界场景处理**</span>

- 空字符串：若传入待分割字符串为空，分割后返回空的`vector`；

- 连续分隔符：通过`!token.empty()`判断可过滤空串，例如`a;;b`分割后仅保留<span style="color:#9221ff">`a`、`b`</span>；

- 首尾分隔符：若字符串以分隔符开头或结尾（如`;a;b;`），会生成空串，需根据业务需求决定是否过滤。

### 4. <span style="color:#209fff">**性能与适用场景**</span>

- 优势：代码简洁、可读性强，对于中小规模字符串，性能优于手动遍历字符的方式；

- 局限：处理超大字符串时，建议使用`std::string::find`手动实现分割，可减少流对象的内存与性能开销。

### 5. <span style="color:#ee4c2e">**【重点】扩展能力**</span>

分割得到的字符串子串，可通过嵌套`std::stringstream`直接转换为<span style="color:#9221ff">int、float、double</span>等数值类型，无需额外编写解析逻辑。

## 二、核心函数参数与功能列表

| 函数名                      | 参数                         | 功能描述                                 |
| ------------------------ | -------------------------- | ------------------------------------ |
| `std::stringstream`      | `const std::string& str`   | 构造函数：将传入的字符串封装为字符串流对象，支持流的输入与输出操作    |
| `std::getline`           | `std::istream& is`         | 读取流参数：指定要读取的输入流（可传入`stringstream`对象） |
| `std::getline`           | `std::string& str`         | 存储参数：将读取到的子串存入该字符串变量中                |
| `std::getline`           | `char delim`               | 分隔符参数：设定分割终止字符（如`,`、`;`、`            |
| `std::vector::push_back` | `const std::string& val`   | 容器操作：将分割后的有效子串添加至`vector`末尾，保存最终分割结果 |
| `std::string::empty`     | 无                          | 判空函数：检查分割得到的子串是否为空，用于过滤无效空串          |
| `std::stringstream`      | `const std::string& token` | 类型转换：将字符串子串封装为流，用于后续数值类型转换           |
| `operator>>`             | `std::stringstream& ss`    | 流提取符：从字符串流中提取数据，支持基础数据类型的转换          |
| `operator>>`             | `int& num`                 | 数值存储：将流中字符串转换为`int`类型，并存入该变量         |
| `operator>>`             | `float& num`               | 数值存储：将流中字符串转换为`float`类型，并存入该变量       |

## 三、基础示例：按自定义分隔符分割字符串

```cpp
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

std::vector<std::string> splitByDelimiter(const std::string& str, char delimiter) {
    std::vector<std::string> result;
    std::stringstream ss(str);
    std::string token;
    while (std::getline(ss, token, delimiter)) {
        if (!token.empty()) {
            result.push_back(token);
        }
    }
    return result;
}

int main() {
    std::string test_str = "C++;Java;;Python,Go";
    auto parts_semicolon = splitByDelimiter(test_str, ';');
    std::cout << "按分号分割结果：" << std::endl;
    for (const auto& part : parts_semicolon) {
        std::cout << part << std::endl;
    }

    auto parts_comma = splitByDelimiter(test_str, ',');
    std::cout << "\n按逗号分割结果：" << std::endl;
    for (const auto& part : parts_comma) {
        std::cout << part << std::endl;
    }
    return 0;
}
```

### 输出结果

```cpp
按分号分割结果：
C++
Java
Python,Go

按逗号分割结果：
C++;Java;;Python
Go
```

## 四、扩展示例：分割后转换为数值类型

```cpp
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

std::vector<int> splitToInt(const std::string& str, char delimiter) {
    std::vector<int> result;
    std::stringstream ss(str);
    std::string token;
    while (std::getline(ss, token, delimiter)) {
        if (!token.empty()) {
            int num;
            std::stringstream(token) >> num;
            result.push_back(num);
        }
    }
    return result;
}

int main() {
    std::string num_str = "10,25,30,,45";
    auto nums = splitToInt(num_str, ',');
    std::cout << "分割并转换为整数结果：" << std::endl;
    for (int num : nums) {
        std::cout << num << " ";
    }
    return 0;
}
```

### 输出结果

```cpp
分割并转换为整数结果：
10 25 30 45 
```

## 五、使用注意事项

1. <span style="color:#32833a">**【备注】**</span>`std::getline`读取时不会包含分隔符本身，需注意分割后子串的完整性；

2. <span style="color:#32833a">**【备注】**</span>数值转换时，若子串非合法数值（如`abc`转`int`），会导致转换失败，可添加异常处理增强鲁棒性；

3. <span style="color:#32833a">**【备注】**</span>该方法依赖`<sstream>`头文件，使用前需确保引入对应头文件。