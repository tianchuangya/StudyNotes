# C\+\+ 运算符重载笔记

## 一、核心本质

运算符重载就是给 C\+\+ 已有的运算符，重新定义它作用于**自定义类 / 结构体对象**时的行为。

1. 只能重载语言已存在的运算符，不能创造新运算符；

2. 仅作用于类 / 结构体对象，不能修改 int、double 等内置类型的运算规则；

3. 底层本质是**函数重载**，运算符是一种特殊函数。

## 二、禁止重载的运算符（考试必背）

`::`  `.`  `.*`  `?:`  `sizeof`
以上 5 个运算符绝对不允许重载。

## 三、两种主流重载形式

### 1\. 成员函数重载

- 隐含左操作数为当前对象 `this`；

- 语法格式：`返回值 operator运算符(右操作数)`

```cpp
class A {
public:
    A operator+(const A& b); 
};
// 使用：a + b 等价于 a.operator+(b)
```

限制：左操作数必须是本类对象。

### 2\. 全局友元函数重载

- 无隐式 `this` 指针，左右操作数都需要显式传入参数；

- 适用场景：左操作数不是自定义类（例如 `3 + 对象`）；

- 核心优势：友元可直接访问类私有、保护成员，无需调用公有接口。

```cpp
friend A operator+(const A& a, const A& b);
```

### 补充扩展：友元类（运算符重载拓展知识）

声明方式：类内写 `friend class 类名;`，声明位置不区分公私。

1. 作用：让另一个类的全部成员函数都能访问当前类私有成员，多个运算符重载时更简洁；

2. 关键特性：
   
   - 友元单向：B 是 A 的友元 ≠ A 是 B 的友元；
   
   - 不可传递：C 是 B 友元、B 是 A 友元，C 不能访问 A 私有成员；
   
   - 不能继承。

```cpp
class Point {
private:
    int x, y;
    friend class FriendClass; // 声明友元类
public:
    Point(int x=0, int y=0) : x(x), y(y) {}
};

class FriendClass {
public:
    Point operator+(const Point& p1, const Point& p2) {
        Point res;
        res.x = p1.x + p2.x;
        res.y = p1.y + p2.y;
        return res;
    }
};

int main() {
    Point a(1,2), b(3,4);
    FriendClass fc;
    Point c = fc.operator+(a, b);
    return 0;
}
```

说明：日常运算符重载极少使用友元类，全局友元函数更通用。

## 四、运算符重载强制规则

1. 运算符**优先级、结合性、操作数个数**无法修改；

2. 单目重载后仍是单目，双目重载后仍是双目；

3. 不要篡改原有语义，`+` 代表加法、`==` 代表相等判断，符合阅读习惯；

4. 以下运算符**仅能使用成员函数重载**，禁止友元：
   赋值 `=`、下标 `[]`、函数调用 `()`、箭头 `->`

## 五、常用运算符重载分类

1. 双目算术：`+ - * / %`
   只读运算，一般返回全新对象，不修改原对象。

2. 赋值运算符 `=`
   只能成员重载，用于深拷贝，解决浅拷贝内存泄漏。

3. 关系运算符：`== != > < >= <=`
   返回 bool，仅做对象成员比较。

4. 单目自增自减 `++ --`
   区分前置、后置，后置重载必须加 `int` 占位参数区分。

5. 流输入输出 `>> <<`
   只能全局友元重载，左操作数是 cin/cout，不是自定义类。

6. 下标 `[]`、括号 `()`、箭头 `->`
   仅成员重载，分别用于容器、仿函数、智能指针。

## 六、高频易错点汇总

1. 成员重载左操作数必须为本类对象；友元无此限制，可直接访问私有成员；友元单向、无传递性。

2. `++/--` 后置重载必须添加 `int` 占位形参，仅用于编译器区分，无实际运算作用。

3. `<<`、`>>` 只能用友元函数，不能写成类成员函数。

4. 重载函数形参、成员函数尽量加 `const`，保证只读不修改数据。

5. 能返回引用 `&` 就返回引用，减少对象拷贝；纯算术运算除外，需返回临时新对象。

## 七、重载函数返回值标准规范（核心考点）

返回值没有统一规定，遵循「贴合原生运算符语义、减少拷贝、支持链式调用」，分类标准写法如下：

### 1\. 算术运算符 `+ - * / %` → 返回类临时对象

只读运算，不修改原对象，不能返回引用（会产生野引用）

```cpp
class Point {
public:
    int x, y;
    Point operator+(const Point& other) const {
        Point res;
        res.x = this->x + other.x;
        res.y = this->y + other.y;
        return res;
    }
};
```

### 2\. 赋值 / 复合赋值 `= += -= *= /=` → 返回当前类引用

修改自身对象，支持链式赋值 `a = b = c`，仅成员重载

```cpp
// 赋值=
Point& operator=(const Point& other) {
    if (this == &other) return *this; // 防止自赋值
    this->x = other.x;
    this->y = other.y;
    return *this;
}
// 复合赋值 +=
Point& operator+=(const Point& other) {
    this->x += other.x;
    this->y += other.y;
    return *this;
}
```

### 3\. 关系 / 逻辑运算符 `== != < > !` → 返回 bool

用于真假判断，函数末尾加 const

```cpp
bool operator==(const Point& other) const {
    return this->x == other.x && this->y == other.y;
}
bool operator<(const Point& other) const {
    return this->x < other.x;
}
```

### 4\. 自增自减 `++ --`

- 前置：返回对象引用（先修改，返回自身）

- 后置：返回新临时对象（先保存原值，再修改），带 int 占位参数

```cpp
// 前置 ++p
Point& operator++() {
    x++; y++;
    return *this;
}
// 后置 p++
Point operator++(int) {
    Point temp = *this;
    x++; y++;
    return temp;
}
```

### 5\. 流运算符 `<< >>` → 返回流对象引用（ostream& / istream&）

友元重载，支持连续链式输出输入 `cout << a << b`

```cpp
friend ostream& operator<<(ostream& os, const Point& p) {
    os << "x:" << p.x << ", y:" << p.y;
    return os;
}
friend istream& operator>>(istream& is, Point& p) {
    is >> p.x >> p.y;
    return is;
}
```

### 6\. 下标 \[\]、箭头 \-\>、函数调用 \(\)

- `[]`：返回成员引用，支持读写 `arr[0] = 10`

- `->`：多用于智能指针，返回对象指针 / 引用

- `()`：仿函数，返回值根据业务自定义

### 速记口诀

只读运算返新对象，修改自身返引用；
比较判断返回 bool，输入输出返流引用；
自增前置引用、后置临时对象。

## 八、极简总结一句话

运算符重载本质是把运算符当作特殊函数，为自定义类定制运算逻辑；分成员函数、全局友元函数两种主流写法（拓展友元类极少使用），存在固定不可重载运算符与语法限制；多用于实现对象加减、比较、控制台打印、数组下标访问等场景；牢记友元关系单向、不可传递。
