# C\+\+ 类的继承与派生 学习文档

本文章由[尚方咸鱼](https://home.cnblogs.com/u/FishSmallWorld/)编写，后经是天创呀修改

本文档系统整理 C\+\+ 面向对象编程中**基类与派生类、派生类实现、访问控制、构造析构、成员标识、虚基类**等核心知识点，包含定义、语法、代码示例与核心规则，适合学习与复习使用。

## 1、基类与派生类

### 1\.1 类的继承与派生

- **类的继承**：面向对象的核心机制，在保持原有类特性的基础上，进行更具体、更详细的定义。

- **核心用途**：**代码重用性（继承）** \+ **可扩充性（派生）**。

- **示例**：植物大战僵尸中，普通僵尸为基类，路障僵尸、铁门僵尸为派生类。

---

- **继承**：新类从已有类获取原有特性（站在已有类角度）。

- **派生**：从已有类创建新类，并新增自身特性（站在新类角度）。

- **关系**：继承与派生是**同一过程**，仅观察角度不同。

- **目的**：
  
  1. 继承：实现代码重用；
  
  2. 派生：改造原有程序，解决新问题。

### 1\.2 核心概念

1. **基类 / 父类**：被继承的已有类；

2. **派生类 / 子类**：通过派生得到的新类；

3. 一个基类可以派生**多个派生类**；

4. 一个派生类可以继承**多个基类**。

### 1\.3 基类分类

- **直接基类**：直接参与派生当前类的基类；

- **间接基类**：基类的基类及更高层级的基类。

### 1\.4 继承分类

- **单继承**：派生类仅有**1 个**基类（多继承的特例）；

- **多继承**：派生类拥有**多个**基类（多个单继承的组合）。

## 2、派生类

### 2\.1 派生类定义语法

```cpp
// 多继承语法
class 派生类名: 继承方式 基类名1, 继承方式 基类名2,... //默认私有继承
{
    派生类成员声明；
};
```

**示例**：

```cpp
// c1公有继承c2，私有继承c3，保护继承c4
class c1:public c2,private c3,protected c4
{
private:
    int c1_mem=0;  // 新增数据成员
public:
    int fun();     // 新增函数成员
};
```

### 2\.2 代码示例：Rectangle 公有继承 Point

```cpp
#include <iostream>
using namespace std;
// 基类：点
class Point
{
public:
    Point(float xx = 0, float yy = 0) : x(xx), y(yy) {}
    void initPoint(float x = 0, float y = 0)
    {
        this->x = x;
        this->y = y;
    }
    // 移动坐标
    void move(float offX, float offY)
    {
        x += offX;
        y += offY;
    }
    void show() { cout << "this is Point's Show:" << x << y << endl; }
    float getX() const { return x; }
    float getY() const { return y; }

private:
    float x, y;
};
// 派生类：矩形，公有继承Point
class Rectangle : public Point
{
public:
    void initRectangle(float x = 0, float y = 0, float w = 0, float h = 0)
    {
        initPoint(x, y); // 调用基类成员函数
        this->w = w;
        this->h = h;
    }
    void show() { cout << "this is Rectangle's Show:" << w << h << endl; }
    float getW() const { return w; }
    float getH() const { return h; }

private:
    float w, h; // 派生类新增成员
};
int main()
{
    Rectangle r1;
    r1.initRectangle(1, 1, 3.0, 4.0);
    r1.move(2, 1); // 调用基类成员函数
    cout << r1.getX() << ',' << r1.getY() << ',' << r1.getW() << ',' << r1.getH() << endl;
    r1.show();
    return 0;
}
```

> 规则：派生类会继承基类**所有非静态成员**（构造函数、析构函数除外）。

## 2\.3 访问控制

### 2\.3\.1 继承访问规则总表

| 基类成员      | 公有继承 \(public\) | 私有继承 \(private\) | 保护继承 \(protected\) |
| --------- | --------------- | ---------------- | ------------------ |
| public    | public          | private          | protected          |
| protected | protected       | private          | protected          |
| private   | 不可访问            | 不可访问             | 不可访问               |

**详细说明**：

1. 基类`public`成员：
   
   - 公有继承：子类内 / 外均可访问；
   
   - 私有 / 保护继承：子类内可访问，类外不可访问。

2. 基类`protected`成员：三种继承方式下，子类内可访问，类外不可访问。

3. 基类`private`成员：**所有继承方式下，子类均不可直接访问**。

**简易编程建议**：
测试程序中，成员声明为`public`/`protected`，使用**公有继承**，简化访问逻辑。

### 2\.3\.2 记忆技巧

1. 基类`private`成员 → 派生类永远无法直接访问；

2. 基类非`private`成员 → 访问权限**向保守方向变化**（public→protected→private）；

3. 仅**基类 public 成员 \+ 公有继承**，可通过子类对象在类外访问。

### 2\.3\.3 成员访问权限基础

| 成员类型      | 类内访问 | 类外访问（通过对象） |
| --------- | ---- | ---------- |
| public    | 允许   | 允许         |
| protected | 允许   | 禁止         |
| private   | 允许   | 禁止         |

## 2\.4 类型兼容性规则

### 核心定义

在需要**基类对象**的任何位置，都可以使用**公有派生类对象**替代，且派生类仅表现出基类的功能。

### 2\.4\.1 三大规则

1. **派生类对象 → 隐式转换为基类对象**

```cpp
A a1;
B b1;
a1 = b1;
```

2. **派生类对象 → 初始化基类引用**

```cpp
B b1;
A &rf = b1;
```

3. **派生类对象地址 → 转换为基类指针**

```cpp
A *p;
B b;
p = &b;
```

### 2\.4\.2 核心特性：仅发挥基类作用

示例：基类指针指向派生类对象，调用的是**基类成员函数**。

```cpp
#include <iostream>
using namespace std;
class Base1{
public:
    void display() const{ cout << "Base1::display()" << endl; }
};
class Base2 : public Base1{
public:
    void display() const{ cout << "Base2::display()" << endl; }
};
class Derived : public Base2{
public:
    void display() const{ cout << "Derived::display()" << endl; }
};
// 函数参数为基类指针
void fun(Base1 *p){ p->display(); }

int main()
{
    Base1 b1; Base2 b2; Derived d1;
    fun(&b1); fun(&b2); fun(&d1);
    return 0;
}
// 运行结果：全部输出 Base1::display()
```

## 3、派生类的构造函数和析构函数

### 3\.1 派生类构造函数语法

```cpp
// 派生类构造函数完整语法（可主动调用基类有参构造）
派生类名::派生类名(形参表):
    基类名1(基类1实参), 基类名2(基类2实参),  // 主动调用基类有参构造
    成员对象名(对象实参),                     // 初始化内嵌对象有参构造
    普通成员(初始值)                           // 初始化普通数据成员
{
    其他初始化操作;
}

// 核心写法示例：基类含带参构造，派生类主动调用
class Base{
public:
    // 仅定义带参构造，无默认无参构造
    Base(int a){ cout << "基类有参构造调用" << endl; }
};

class Derived : public Base{
public:
    // 必须在初始化列表主动调用基类有参构造，否则编译报错
    Derived(int x) : Base(x) {
        cout << "派生类构造调用" << endl;
    }
};
```

**默认构造函数使用条件**：

1. 无需调用基类带参构造函数；

2. 无需调用内嵌对象带参构造函数。

> 系统自动生成默认构造函数，调用基类 / 对象的默认构造函数（无参构造函数）。
> 
> **核心补充规则（高频易错）**：
> 
> - **默认调用规则**：派生类默认构造函数，会**自动调用所有直接基类、内嵌成员对象的无参构造函数**，无需手动书写。
> 
> - **报错场景**：若基类**只定义了带参构造函数、未定义无参构造函数**（系统不会自动生成默认无参构造），派生类默认构造时找不到可用的无参构造，直接编译报错。
> 
> - **解决方案1**：基类手动补充无参构造函数。
> 
> - **解决方案2**：派生类显式定义构造函数，在初始化列表中**主动调用基类的有参构造函数**，强制覆盖默认调用逻辑。

### 3\.2 构造函数调用顺序 \&amp; 核心调用规则

### 3\.2 构造函数调用顺序

1. **基类构造函数**：严格按照**类继承声明顺序**调用，与构造函数初始化列表书写顺序无关；未手动指定则默认调用无参构造，需传参则必须在初始化列表显式调用。

2. **内嵌对象构造函数**：按照类内成员**声明先后顺序**调用。

3. **派生类自身构造函数**：最后执行派生类构造函数函数体内部逻辑。

### 3\.3 代码示例：多继承 \+ 内嵌对象构造

```cpp
#include <iostream>
using namespace std;
class Base1{public: Base1(int i) { cout << "Constructing Base1 " << i << endl; }};
class Base2{public: Base2(int i) { cout << "Constructing Base2 " << i << endl; }};
class Base3{public: Base3() { cout << "Constructing Base3 *" << endl; }};

// 继承顺序：Base2 → Base1 → Base3
class Derived : public Base2, public Base1, public Base3
{
public:
    Derived(int a,int b,int c,int d):Base1(a),m2(d),m1(c),Base2(b) {}
private:
    Base1 m1;
    Base2 m2;
    Base3 m3;
};
int main(){ Derived obj(1,2,3,4); return 0; }
```

**运行结果**：

```Plain
Constructing Base2 2
Constructing Base1 1
Constructing Base3 *
Constructing Base1 3
Constructing Base2 4
Constructing Base3 *
```

### 3\.4 派生类复制构造函数

```cpp
// 语法
Derived::Derived(const Derived &v):Base(v){}
```

- 系统默认生成复制构造函数，自动调用基类复制构造函数；

- 基类`delete`复制构造函数，派生类也无法拷贝。

### 3\.5 派生类析构函数

1. 语法：`Derived::\~Derived\(\)\{\}`，与普通类写法一致；

2. 自动调用基类和内嵌对象的析构函数；

3. **执行顺序：与构造函数严格相反**。

**析构顺序**：派生类析构 → 内嵌对象析构 → 基类析构。

### 3\.6 析构函数示例

对 3\.3 代码添加析构函数，运行结果中析构顺序与构造完全相反。

## 4、派生类成员的标识和访问

### 4\.1 作用域分辨符 `::`

用于区分同名成员，格式：`类名::成员名`

### 4\.2 同名成员隐藏规则

1. 派生类定义与基类**同名函数**（无论参数是否相同），基类所有重载函数被**隐藏**；

2. 同名隐藏≠函数重载（重载要求同一作用域）；

3. 调用基类同名函数：必须加`基类名::`限定。

**示例**：

```cpp
class Base{
public:
    void print();
    void print(int i);
};
class Derived:public Base{
public:
    void print(int i,int j,int k); // 隐藏基类所有print
};
// 错误用法：d.print() / d.print(1)
// 正确用法：d.Base::print()
```

### 4\.3 多继承同名二义性

1. 多个基类有同名成员，派生类未定义 → 访问产生**二义性**；

2. 解决方案：
   
   - 方式 1：`基类名::`限定；
   
   - 方式 2：派生类定义同名成员，隐藏基类成员。

### 4\.4 多层继承同名问题

多个派生类继承同一个基类，会导致成员冗余、赋值不一致 → **虚基类**解决。

## 5、虚基类

### 5\.1 解决问题

消除**多层多继承**中共同基类带来的**成员冗余、数据不一致**问题。

### 5\.2 声明语法

```cpp
class 派生类: virtual 继承方式 基类名{};
```

> 关键：**第一级继承**就必须声明为虚基类。

### 5\.3 代码示例

```cpp
#include <iostream>
using namespace std;
// 虚基类
class Base0
{
public:
    int var0;
    void fun0() { cout << "Base0 var0=" << var0 << endl; }
};
// 虚继承
class Base1 : virtual public Base0 {};
class Base2 : virtual public Base0 {};
// 最终派生类
class Derived : public Base1, public Base2 {};

int main()
{
    Derived d;
    d.var0 = 2; // 直接访问，无冗余、无二义性
    d.fun0();
    return 0;
}
```

### 5\.4 核心规则

1. 虚基类成员由**最远派生类**的构造函数初始化；

2. 仅最远派生类调用虚基类构造函数，其他类调用被忽略；

3. 虚基类有带参构造函数时，所有派生类必须在初始化列表中初始化。

---

### 总结

1. 继承实现代码重用，派生实现功能扩展，公有继承是最常用方式；

2. 派生类构造顺序：基类→内嵌对象→自身，析构顺序相反；

3. 同名成员用`::`区分，多继承二义性通过虚基类解决；

4. 类型兼容性规则：公有派生类对象可替代基类对象，仅表现基类功能。
