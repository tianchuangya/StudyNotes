# C++ 模板 核心知识点梳理

C++ 模板是**泛型编程**的核心，用来实现**代码复用 + 类型无关**，让一份代码支持多种数据类型，分为**函数模板**和**类模板**两大类。

### 一、模板是什么？

一句话：**模板就是代码的 “模具”**，编译器会根据你传入的类型（int/double/ 自定义类等），自动生成对应类型的代码。

- 优点：代码复用、类型安全、无运行时开销
- 本质：**编译期多态**（不同于虚函数的运行时多态）

### 二、函数模板

1. 基本语法

```cpp
// 模板声明
template <typename T>  // T 是类型参数（typename = class）class是以前写法不推荐
T add(T a, T b) {
    return a + b;
}
```

  2.使用方式

```cpp
// 自动推导类型（推荐）
cout << add(1, 2) << endl;       // int
cout << add(1.1, 2.2) << endl;   // double

// 显式指定类型
cout << add<int>(3, 4) << endl;
```

注意：在使用该模板时，**所有输入参数的类型必须保持一致，均为同一类型 T**。

3.多参数模板

```cpp
template <typename T1, typename T2>
void print(T1 a, T2 b) {
    cout << a << " " << b << endl;
}
```

### 三、类模板

1.基本语法

```cpp
template <typename T>
class MyVector {
private:
    T* data;
public:
    void push(T val);
};

// 类外实现成员函数
template <typename T>
void MyVector<T>::push(T val) {
    // 逻辑
}
```

2.使用方式

**类模板必须显式指定类型**，无法自动推导，即：类模板在定义对象时，必须用 `<类型>` 显式告诉编译器

举个例子：在上述MyVector类创建int类型的vector：`MyVecotr<int>(1)`



3.非参数型模板参数

模板参数不只是**类型**，还可以是**常量值**（整数、指针等）：

```cpp
template <typename T, int SIZE>  // SIZE 是数值
class Array {
    T arr[SIZE];
};

// 使用
Array<int, 10> arr;  // 定义一个大小为10的数组
```

### 四：注意点

1、在声明一个需要使用到模板的函数/类时，必须在其上方加上对应模板声明，即：一个模板对应一个函数/类，同一个 `template<...>` 不能同时给多个函数 / 类共用。

2、类模板必须写 <类型>，不能自动推导

3、函数模板可以自动推导，但参数类型必须一致
