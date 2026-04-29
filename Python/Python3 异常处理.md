# Python3 异常处理

# **Python3 错误和异常 核心知识点文档**

## **一、核心概念：错误 vs 异常**

| 类别                                              | 标识特征                                              | 触发阶段        | 典型示例                                                                                                       | 处理方式                                                                          |
| ----------------------------------------------- | ------------------------------------------------- | ----------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| <font color="#209aff">语法错误（Syntax Error）</font> | <font color="#ee4c2e">**编译期错误，程序无法运行**</font>     | 代码解析阶段（运行前） | <font color="#9221ff">缺少冒号：`if 1>0 print("err")`；缩进错误：`def f():print("err")`；括号不匹配：`print("hello")`</font> | <font color="#32833a">备注：直接修正语法，严格遵循Python规范（如冒号、缩进、括号匹配）</font>              |
| <font color="#209aff">异常（Exception）</font>      | <font color="#ee4c2e">**运行时错误，程序中断（未处理时）**</font> | 代码执行阶段（运行中） | <font color="#9221ff">除零：`10/0`；索引越界：`[1,2][5]`；类型错误：`"2"+2`；访问不存在变量：`print(undefined_var)`</font>         | <font color="#32833a">备注：通过`try-except`捕获处理，或`raise`主动抛出，或自定义异常类适配业务场景</font> |

## **二、异常处理核心语法（重点）**

### **1. 基础捕获：try-except-else-finally**

<font color="#ff4541">**核心作用：捕获运行时异常，避免程序崩溃，实现可控的异常处理逻辑**</font>

```python
try:
    # 包裹可能触发异常的代码块（核心监控区域）
    num = int(input("请输入一个数字："))
    result = 10 / num  #示例：可能触发ZeroDivisionError（除零）或ValueError（非数字输入
except ZeroDivisionError as e:
    # 捕获指定异常类型，e为异常对象（存储错误详情）
    print(f"错误：{e}（除数不能为0）")
except ValueError as e:
    # 捕获多个不同类型的异常，分别处理
    print(f"错误：{e}（请输入有效的整数）")
else:
    # 备注：仅当try块无任何异常时执行，处理正常逻辑
    print(f"计算结果：10 ÷ {num} = {result}")
finally:
    # 备注：无论是否发生异常，必然执行（释放资源的首选场景）
    print("程序执行完毕（finally分支：资源已释放）")  # 示例：关闭文件`file.close()`、数据库连接`conn.close()`
```

### **2. 主动抛出异常：raise**

<font color="#ff4541">**核心作用：手动触发异常，适配自定义校验场景（如参数合法性、业务规则校验）**</font>

```python
def check_age(age):
    """校验年龄合法性（0-150岁）"""
    if not isinstance(age, int):
        # 抛出类型错误，提示参数类型异常
        raise TypeError("年龄必须是整数类型")  # 示例1：触发TypeError
    if age < 0 or age > 150:
        # 抛出值错误，附带具体错误描述
        raise ValueError(f"年龄{age}无效（合法范围：0-150岁）")  # 示例2：触发ValueError
    print(f"年龄{age}校验通过")

# 测试主动抛出异常
try:
    check_age(200)  # 触发ValueError
    # check_age("25")  # 触发TypeError
except (TypeError, ValueError) as e:
    print(f"捕获异常：{e}")
```

### **3. 自定义异常类**

<font color="#ff4541">**核心作用：适配业务专属异常场景（如登录失败、密码错误），提升代码可读性和维护性**</font>

<font color="green">**备注：自定义异常类必须继承** **`Exception`** **基类（所有内置异常的父类），可重写构造方法和字符串展示方法**</font>

```python
# 自定义业务异常类：密码相关异常
class PasswordError(Exception):
    """自定义密码异常类（适用于密码校验场景）"""
    def __init__(self, msg):
        # 初始化异常描述信息
        self.msg = msg  #示例：接收"密码长度不足"等具体描述

    def __str__(self):
        # 重写异常打印格式，提升可读性
        return f"【密码异常】{self.msg}"

# 自定义业务异常类：登录相关异常
class LoginError(Exception):
    """自定义登录异常类（适用于登录校验场景）"""
    def __init__(self, username, msg):
        self.username = username  # 附加用户名信息
        self.msg = msg

    def __str__(self):
        return f"【登录异常】用户{self.username}：{self.msg}"

# 使用自定义异常
def check_password(pwd):
    if len(pwd) < 6:
        raise PasswordError("密码长度不能少于6位")  # 触发自定义PasswordError
    if not any(char.isdigit() for char in pwd):
        raise PasswordError("密码必须包含至少一位数字")  # 触发自定义PasswordError
    print("密码校验通过")

def user_login(username, pwd):
    try:
        check_password(pwd)
    except PasswordError as e:
        # 捕获自定义异常，可进一步处理或重新抛出
        raise LoginError(username, e.msg) from e  # 备注：`from e`保留异常链，便于调试
    print(f"用户{username}登录成功")

# 测试自定义异常
try:
    user_login("zhangsan", "12345")
except LoginError as e:
    print(e)  # 输出：【登录异常】用户zhangsan：密码长度不能少于6位
```

## **三、常见内置异常（高频场景）**

| <font color="#5ebaff">异常类型</font> | 触发场景              | <font color="#9221ff">示例代码</font>                                 | <font color="#32833a">备注</font> |
| --------------------------------- | ----------------- | ----------------------------------------------------------------- | ------------------------------- |
| ZeroDivisionError                 | 除零运算              | `10 / 0`、`5 // 0`                                                 | 算术运算中除数为0的专属异常                  |
| NameError                         | 访问未定义的变量/函数       | `print(undefined_var)`、`func_not_defined()`                       | 变量未声明或作用域错误导致                   |
| TypeError                         | 数据类型不兼容的操作        | `"2" + 2`、`[1].append("str")`、`int(None)`                         | 操作与数据类型不匹配                      |
| IndexError                        | 序列（列表/元组/字符串）索引越界 | `[1,2,3][5]`、`("a","b")[3]`、`"hello"[10]`                         | 索引超出序列长度（Python索引从0开始）          |
| KeyError                          | 字典访问不存在的键         | `{"name":"Tom"}["age"]`、`dict.get("key", "default")`（无默认值时）       | 字典中无该键，需先判断或使用`get()`方法         |
| FileNotFoundError                 | 打开不存在的文件          | `open("nonexist.txt", "r")`                                       | 文件路径错误或文件不存在                    |
| ValueError                        | 数值转换失败或参数逻辑无效     | `int("abc")`、`float("xyz")`、`list.remove(99)`（列表中无99）             | 参数类型正确但值不符合逻辑                   |
| AttributeError                    | 访问对象不存在的属性/方法     | `"hello".nonexist_method()`、`class Instance: pass; Instance.attr` | 对象无此属性或方法（拼写错误常见）               |
| ImportError                       | 导入模块失败            | `import non_exist_module`、`from package import wrong_module`      | 模块未安装或路径错误                      |

<div>
<font color="#ee4c2e" size=6>极简记忆口诀（背会这几句，覆盖 90% 场景）</font>
</div>

> 除零用 Zero，类型错 Type，值无效 Value；名字错 Name，索引错 Index，键错 Key；文件没找到 FileNotFound，属性错 Attribute。 

| 口诀片段                       | 触发场景（一句话记）        |
| -------------------------- | ----------------- |
| <u>除零</u>用 `Zero`          | 除法/取模运算中，除数为0     |
| <u>类型错</u> `Type`          | 操作/函数传入“类型不匹配”的参数 |
| <u>值无效</u> `Value`         | 参数“类型正确但值不符合逻辑”   |
| <u>名字错</u> `Name`          | 访问“未定义/未赋值”的变量或函数 |
| <u>索引错</u> `Index`         | 列表/元组/字符串的索引超出范围  |
| <u>键错</u> `Key`            | 访问字典中“不存在的键”      |
| <u>文件没找到`</u>FileNotFound` | 打开的文件不存在，或文件路径错误  |
| <u>属性错</u> `Attribute`     | 访问对象“不存在的属性或方法”   |

## **四、异常处理最佳实践（重点）**

1. <font color="#ee4c2e">**精准捕获异常，避免广谱捕获**</font>优先捕获具体异常（如`ZeroDivisionError`），而非直接捕获`Exception`或省略异常类型（`except:`），防止掩盖未知错误（如语法错误、系统级异常）。<font color="#9221ff">反例：</font>
   
   ```python
   try:
       10 / 0
   except:  # 错误：捕获所有异常，无法定位问题
       print("发生错误")
   ```
   
    <font color="#9221ff">正例：</font>
   
   ```python
   try:
       10 / 0
   except ZeroDivisionError as e:  # 精准捕获，明确问题类型
       print(f"除零错误：{e}")
   ```

2. <font color="#ff4541">**禁用空except分支**</font>不允许`except:`后无任何处理逻辑，否则错误会被隐藏，调试时无法定位问题。若暂时无法处理，需打印异常信息（`print(e)`）或记录日志。

3. <font color="green">**使用finally释放资源**</font>文件、数据库连接、网络连接等资源，必须在`finally`中关闭，确保无论是否发生异常，资源都会被释放（避免资源泄露）。<font color="#9221ff">示例：</font>
   
   ```python
   file = None
   try:
       file = open("data.txt", "r")
       data = file.read()
   except FileNotFoundError as e:
       print(f"文件未找到：{e}")
   finally:
       if file:  # 判断文件是否成功打开
           file.close()  # 确保文件关闭
   ```

4. <font color="#32833a">**异常描述清晰，附带上下文信息**</font>抛异常时添加具体描述（如`raise ValueError("年龄需在0-150岁之间，当前为200")`），便于调试时快速定位问题；捕获异常时可记录上下文（如用户ID、参数值）。

5. <font color="#ff4541">**自定义异常适配业务场景**</font>复杂业务中（如支付、登录、数据校验），使用自定义异常类区分通用异常和业务异常（如`PasswordError`、`PaymentFailedError`），提升代码可读性和错误处理效率。

6. <font color="#32833a">**保留异常链，便于调试**</font>重新抛出异常时使用`raise 新异常 from 原异常`，保留原始异常的堆栈信息，便于追踪异常根源。<font color="#9221ff">示例：</font>
   
   ```python
   try:
       check_password("12345")
   except PasswordError as e:
       # 保留原始异常链，调试时可查看完整堆栈
       raise LoginError("zhangsan", "登录失败") from e
   ```

7. <font color="#32833a">**避免在异常处理中忽略严重错误**</font>系统级异常（如`MemoryError`、`KeyboardInterrupt`）通常需要终止程序或向上传递，不应随意捕获并忽略。

## **五、异常相关核心函数/语句列表（宽表版）**

| 函数/语句（黑体）                  | 参数                                        | 功能描述                              | <font color="#32833a">备注</font>                          |
| -------------------------- | ----------------------------------------- | --------------------------------- | -------------------------------------------------------- |
| **try**                    | 无显式参数                                     | 定义待监控的异常代码块，是异常捕获的起始标识            | 必须与`except`、`finally`或`else`配合使用，不可单独存在                  |
| **except**                 | 异常类型（如`ZeroDivisionError`、`ValueError`）   | 指定要捕获的具体异常类型，精准匹配异常场景             | 可同时捕获多个异常（用元组包裹：`except (TypeError, ValueError):`）       |
| **except**                 | as e                                      | 将捕获的异常对象赋值给变量`e`，用于获取错误详情（如描述、堆栈） | 可选参数，`e`是异常实例，包含`args`（异常参数）、`with_traceback()`（堆栈信息）等属性 |
| **else**                   | 无显式参数                                     | 仅当`try`块无任何异常时执行，处理正常业务逻辑         | 可选分支，必须位于所有`except`之后、`finally`之前                        |
| **finally**                | 无显式参数                                     | 无论`try`块是否触发异常，均执行该分支             | 核心用于释放资源（文件、连接等），可选分支，可单独与`try`配合（无`except`）             |
| **raise**                  | 异常类型（如`ValueError`、自定义异常类`PasswordError`） | 手动触发指定类型的异常，主动中断当前程序逻辑            | 必选核心参数，异常类型必须是`Exception`的子类                             |
| **raise**                  | "异常描述字符串"                                 | 为抛出的异常添加自定义描述信息，提升错误可读性           | 可选参数，会作为异常对象的`args[0]`属性存储                               |
| **raise**                  | 异常实例（如`ValueError("无效值")`）                | 直接抛出已创建的异常实例                      | 适用于需要复用异常对象的场景                                           |
| **raise**                  | from 原异常实例                                | 保留异常链，将当前异常与原异常关联                 | 用于重新抛出异常时，保留原始异常堆栈（Python 3.3+支持）                        |
| **class（自定义异常）**           | Exception（父类）                             | 定义自定义异常类，必须继承`Exception`基类        | 所有内置异常均继承自`Exception`，不可继承`BaseException`（包含系统级异常）       |
| **init（自定义异常）**            | self                                      | 异常类的构造方法必传参数，指向当前实例               | 所有类的构造方法都必须包含`self`参数，不可省略                               |
| **init（自定义异常）**            | msg（自定义描述参数）                              | 接收自定义异常的描述信息，存储到实例属性              | 可选参数，可根据业务需求添加多个参数（如`username`、`error_code`）             |
| **str（自定义异常）**             | self                                      | 重写该方法，自定义异常打印时的字符串格式              | 可选方法，不重写则默认返回异常类名和`args`参数                               |
| **isinstance**             | 异常对象（如`e`）                                | 判断目标对象是否为指定异常类型的实例                | 用于动态校验异常类型（如多异常捕获后的分支处理）                                 |
| **isinstance**             | 异常类型（如`ValueError`、`TypeError`）           | 指定要校验的目标异常类型                      | 支持校验多个类型（用元组包裹：`isinstance(e, (TypeError, ValueError))`） |
| **Exception**              | 无显式参数                                     | 所有内置异常的基类，可捕获全部内置异常               | 仅在特殊场景使用（如全局异常捕获），慎用（可能掩盖未知错误）                           |
| **traceback.print_exc()**  | 无显式参数                                     | 打印异常的完整堆栈信息（包含文件名、行号、错误链路）        | 需导入`traceback`模块，用于调试时定位异常根源                             |
| **traceback.format_exc()** | 无显式参数                                     | 将异常堆栈信息转换为字符串，便于日志记录              | 适用于生产环境，避免直接打印堆栈到控制台                                     |

## **六、补充说明**

- <font color="#32833a">**异常与错误的区别**</font>：语法错误是编译期错误，无法通过代码处理，必须修正语法；异常是运行时错误，可通过`try-except`捕获处理，程序可继续执行。

- <font color="#32833a">**Python异常的继承关系**</font>：所有异常的顶层父类是`BaseException`，`Exception`是所有内置业务异常的父类（`SystemExit`、`KeyboardInterrupt`等系统异常直接继承`BaseException`，通常不捕获）。

- <font color="#32833a">**日志记录异常**</font>：生产环境中，应使用`logging`模块记录异常（而非`print`），包含时间、上下文、堆栈信息，便于问题排查。<font color="#9221ff">示例：</font>
  
  ```python
  import logging
  
  logging.basicConfig(filename="error.log", level=logging.ERROR)
  try:
      10 / 0
  except ZeroDivisionError as e:
      logging.error(f"除零错误：{e}", exc_info=True)  # exc_info=True记录堆栈信息
  ```

---

**文档说明**：本文档基于Python 3.x版本编写，涵盖错误和异常的核心概念、语法、常见场景、最佳实践及相关API，适用于编程初学者系统学习Python异常处理机制，可作为开发中的参考手册。