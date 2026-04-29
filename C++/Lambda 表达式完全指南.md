# Lambda 表达式知识点总结

> 本文是个人学习笔记，理解可能有误，欢迎指正！

## 什么是Lambda表达式？

Lambda表达式是C++11引入的**匿名函数**特性，允许在代码中内联定义函数，无需单独声明。

```
[捕获列表](参数列表) { 函数体 }
```

## Lambda的基本用法

### 1. 立即执行的Lambda

```cpp
// 定义后立即调用
[]() {
 std::cout << "Hello, Lambda!" << std::endl;
}(); // 输出: Hello, Lambda!
```

### 2. 带参数的Lambda

```cpp
// 接受参数并返回结果
auto sum = [](int a, int b) {
 return a + b;
};
std::cout << sum(5, 3) << std::endl; // 输出: 8
```

### 3. 赋值给变量的Lambda

```cpp
// Lambda可以赋值给auto变量
auto greet = [](const std::string& name) {
 std::cout << "Hello, " << name << "!" << std::endl;
};
greet("Alice"); // 输出: Hello, Alice!
greet("Bob"); // 输出: Hello, Bob!
```

> **提示：** 使用**auto**关键字存储Lambda时，变量的类型是编译器生成的唯一闭包类型。如果需要明确指定类型，可以使用**std::function**。

## 捕获外部变量

Lambda可以捕获其定义范围内的变量，这是它与普通函数的主要区别之一。

注释：Lambda 只能抓【上面 / 前面】已经定义好的变量，抓不到【下面 / 后面】还没定义的变量，并且只能抓定义时所在函数变量

### 1. 值捕获（默认不修改原变量）

```cpp
int count = 0;
// 值捕获 - 创建副本
auto increment_copy = [count]() {
 // count++; // 错误！不能修改捕获的副本
 return count + 1;
};
std::cout << increment_copy() << std::endl; // 输出: 1
std::cout << count << std::endl; // 输出: 0 (原值未变)
```

### 2. 使用mutable修改副本

```cpp
int count = 0;
// mutable允许修改副本（但不影响原变量）
auto increment_mutable = [count]() mutable {
 count++; // 修改的是副本
 return count;
};
std::cout << increment_mutable() << std::endl; // 输出: 1
std::cout << increment_mutable() << std::endl; // 输出: 2
std::cout << count << std::endl; // 输出: 0 (原值未变)
```

### 3. 引用捕获（可以修改原变量）

```cpp
int count = 0;
// 引用捕获 - 可以修改原变量
auto increment_ref = [&count]() {
 count++; // 修改原变量
 return count;
};
std::cout << increment_ref() << std::endl; // 输出: 1
std::cout << count << std::endl; // 输出: 1 (原值被修改)
```

## 泛型Lambda (C++14)

C++14引入了泛型Lambda，允许参数类型自动推断。

```cpp
// 泛型Lambda - 可以处理多种类型
auto add = [](auto x, auto y) {
 return x + y;
};
// 可以用于各种类型
std::cout << add(5, 3) << std::endl; // 输出: 8 (int + int)
std::cout << add(2.5, 3.7) << std::endl; // 输出: 6.2 (double + double)
std::string a = "Hello ";
std::string b = "World";
std::cout << add(a, b) << std::endl; // 输出: Hello World (string + string)
```

## Lambda作为返回值

Lambda可以方便地从函数返回，创建闭包。

```cpp
// 函数返回Lambda
auto create_multiplier = [](auto factor) {
 return [factor](auto x) { return x * factor; };
};
auto double_it = create_multiplier(2);
auto triple_it = create_multiplier(3);
std::cout << double_it(5) << std::endl; // 输出: 10
std::cout << triple_it(5) << std::endl; // 输出: 15
```

## 捕获方式总结

```
[] // 不捕获任何变量
[=] // 所有变量值捕获
[&] // 所有变量引用捕获
[x] // 仅x值捕获
[&x] // 仅x引用捕获
[=, &x] // 除x引用捕获外，其他值捕获
[&, x] // 除x值捕获外，其他引用捕获
```

## 关键知识点回顾

- **Lambda是匿名函数** - 由`[](){}`组成，可以没有名字
- **可以捕获外部变量** - 这是与普通函数的主要区别
- **默认值捕获不修改原变量** - 创建的是副本
- **使用mutable可修改值捕获的副本** - 但不影响原变量
- **引用捕获可修改原变量** - 使用`&`符号
- **C++14支持泛型Lambda** - 使用`auto`参数
- **Lambda类型是唯一的闭包类型** - 每个Lambda都有独特的类型
  
  > **注意：** 引用捕获要特别小心生命周期问题。如果Lambda的生命周期超过了它捕获的引用变量，会导致悬空引用。
  
  ## 实际应用场景
1. **一次性使用逻辑** - 不需要专门定义函数
2. **回调函数** - 事件处理、异步操作
3. **算法定制** - STL算法的自定义比较器、过滤器
4. **快速测试** - 快速验证想法
5. **函数式编程** - 创建高阶函数、闭包
   **总结：** Lambda表达式是现代C++中非常重要的特性，它让代码更简洁、更安全、更易于维护，在多种场景下都能发挥作用！
