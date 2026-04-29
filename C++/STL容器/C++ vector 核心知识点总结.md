# C++ vector 核心知识点总结（完整补全版）

## 一、vector 初始化方式

vector 提供多种灵活的初始化方法，适配不同使用场景：

### 1. 默认初始化（空 vector）

创建无元素的空容器，需后续添加元素：

```cpp
#include <vector>
using namespace std;
// 默认初始化空vector
vector<int> vec1; // 空的int类型vector，size=0，capacity=0
vector<string> vec2; // 空的string类型vector
```

### 2. 指定元素数量和初始值

直接定义容器大小并设置默认值：

```cpp
// 创建包含5个元素，每个元素值为0的vector
vector<int> vec3(5); // size=5，capacity=5，元素：[0,0,0,0,0]
// 创建包含5个元素，每个元素值为10的vector
vector<int> vec4(5, 10); // size=5，capacity=5，元素：[10,10,10,10,10]
// 创建包含3个字符串"hello"的vector
vector<string> vec5(3, "hello"); // ["hello", "hello", "hello"]
```

### 3. 初始化列表（C++11 及以上）

直接用大括号指定元素，简洁直观：

```cpp
// 直接初始化元素：1,2,3,4,5
vector<int> vec6{1, 2, 3, 4, 5}; 
vector<int> vec7 = {6, 7, 8}; // 等价写法，C++11支持
vector<string> vec8{"apple", "banana", "orange"};
```

### 4. 拷贝初始化

通过已有 vector 创建新容器（拷贝所有元素，新容器独立）：

```cpp
vector<int> src{1,2,3};
// 拷贝src的所有元素，vec9与src内容相同但内存独立
vector<int> vec9(src); 
vector<int> vec10 = src; // 等价写法
```

### 5. 移动初始化（C++11 及以上）

转移已有 vector 的资源（原容器变为空，避免拷贝，效率高）：

```cpp
vector<int> src{1,2,3};
// 移动初始化：vec11接管src的内存，src变为空
vector<int> vec11(move(src)); 
// 此时src.size()=0，vec11的元素为[1,2,3]
```

### 6. 赋值函数初始化（assign）

通过 assign 函数批量设置元素（覆盖原有元素）：

```cpp
vector<int> vec12{10,20,30};
// 覆盖为5个值为8的元素
vec12.assign(5, 8); // vec12: [8,8,8,8,8]
vector<int> src{1,2,3};
// 赋值src的区间元素
vec12.assign(src.begin(), src.end()); // vec12: [1,2,3]
// C++11：赋值初始化列表
vec12.assign({4,5,6}); // vec12: [4,5,6]
```

## 二、二维 vector（vector<vector<T>>）操作

### 1. 初始化（固定大小 + 初始值）

直接定义行数 m、列数 n 及元素默认值：

```cpp
// 方式1：直接初始化m行n列，所有元素为0
int m = 3, n = 4;
vector<vector<int>> mat1(m, vector<int>(n, 0)); 
// mat1: 
// [0,0,0,0]
// [0,0,0,0]
// [0,0,0,0]
// 方式2：先创建空二维vector，再逐行添加
vector<vector<int>> mat2;
mat2.push_back({1,2,3}); // 第一行：[1,2,3]
mat2.push_back({4,5}); // 第二行：[4,5]（非规则矩阵）
mat2.push_back({6}); // 第三行：[6]
// 方式3：动态初始化（结合resize）
vector<vector<int>> mat3;
mat3.resize(m); // 先设置行数为m
for (int i = 0; i < m; ++i) {
 mat3[i].resize(n, 1); // 每行设置n列，值为1
}
```

### 2. 获取行数和列数

| 需求        | 代码写法                               | 说明                                  |
| --------- | ---------------------------------- | ----------------------------------- |
| 获取行数      | mat1.size()                        | 外层 vector 的元素个数即行数                  |
| 基础获取列数    | mat1[0].size()                     | 第一行（索引 0）的元素个数即列数（需确保 vector 非空）    |
| 安全获取列数    | !mat1.empty() ? mat1[0].size() : 0 | 先判断容器是否为空，避免空容器访问 mat1[0] 导致崩溃      |
| 获取第 i 行列数 | mat2[i].size()                     | 非规则矩阵中，逐行获取列数（如 mat2[1].size() = 2） |

### 3. 注意事项

二维 vector 支持“非规则矩阵”（每行列数可不同），需逐行获取列数时用 `a[i].size()`。例如：

```cpp
vector<vector<int>> mat{{1,2}, {3}, {4,5,6}};
cout << mat[0].size(); // 输出2
cout << mat[1].size(); // 输出1
cout << mat[2].size(); // 输出3
```

## 三、vector 核心成员函数（按功能分类）

### 1. 元素访问函数

| 函数        | 功能描述                                        |
| --------- | ------------------------------------------- |
| at(index) | 访问索引 index 的元素，带边界检查（越界抛 `out_of_range` 异常） |
| [index]   | 访问索引 index 的元素，无边界检查（效率更高，需确保索引合法）          |
| front()   | 返回容器第一个元素（容器非空时有效）                          |
| back()    | 返回容器最后一个元素（容器非空时有效）                         |
| data()    | 返回指向底层数组的指针（可直接操作底层数据，C++11+）               |
| **示例代码**： |                                             |

```cpp
vector<int> vec{10,20,30,40};
cout << vec.at(1); // 输出20，带边界检查
cout << vec[2]; // 输出30，无边界检查
cout << vec.front(); // 输出10
cout << vec.back(); // 输出40
// data() 操作底层数组
int* ptr = vec.data();
ptr[1] = 200; // 修改第二个元素，vec变为[10,200,30,40]
```

### 2. 容量相关函数

| 函数              | 功能描述                                             |
| --------------- | ------------------------------------------------ |
| empty()         | 判断容器是否为空（无元素返回 true，否则 false）                    |
| size()          | 返回容器中当前元素的个数                                     |
| capacity()      | 返回容器当前分配的存储容量（可容纳的元素数，可能大于 size()）               |
| max_size()      | 返回容器理论上可容纳的最大元素数（受系统/编译器限制）                      |
| reserve(n)      | 预分配存储空间，确保至少能容纳 n 个元素（不改变 size()，仅提升 capacity()） |
| shrink_to_fit() | 请求释放多余容量，使 capacity() 适配当前 size()（C++11 及以上，非强制） |
| **示例代码**：       |                                                  |

```cpp
vector<int> vec{1,2,3};
cout << vec.empty(); // 输出false
cout << vec.size(); // 输出3
cout << vec.capacity(); // 输出3（默认初始化容量等于size）
vec.reserve(10); // 预分配容量到10
cout << vec.size(); // 仍为3
cout << vec.capacity();// 输出10
vec.push_back(4);
vec.shrink_to_fit(); // 释放多余容量
cout << vec.capacity(); // 输出4（适配当前size=4）
```

### 3. 元素修改器函数（添加/删除/调整）

#### （1）添加元素

| 函数                    | 功能描述                                             |
| --------------------- | ------------------------------------------------ |
| push_back(elem)       | 在容器末尾添加一个 elem 的拷贝                               |
| emplace_back(elem)    | 在容器末尾直接构造 elem（C++11+，效率高于 push_back，避免拷贝/移动）    |
| insert(pos, elem)     | 在迭代器 pos 位置插入 elem 的拷贝，返回新元素的迭代器                 |
| insert(pos, n, elem)  | 在迭代器 pos 位置插入 n 个 elem 的拷贝，无返回值                  |
| insert(pos, beg, end) | 在迭代器 pos 位置插入 [beg, end) 区间的元素，返回新元素的迭代器（C++11+） |
| **示例代码**：             |                                                  |

```cpp
vector<int> vec{1,2,3};
vec.push_back(4); // vec: [1,2,3,4]
// 直接构造5，避免拷贝（对于复杂类型如自定义类更高效）
vec.emplace_back(5); // vec: [1,2,3,4,5]
// 插入元素：在第二个位置（索引1）插入10
auto it = vec.insert(vec.begin()+1, 10); // it指向插入的10
// vec: [1,10,2,3,4,5]
// 插入3个9，在迭代器it位置
vec.insert(it, 3, 9); // vec: [1,9,9,9,10,2,3,4,5]
vector<int> src{88,99};
// 插入src的区间元素到末尾
vec.insert(vec.end(), src.begin(), src.end()); // vec末尾添加88,99
```

#### （2）删除元素

| 函数              | 功能描述                                   |
| --------------- | -------------------------------------- |
| pop_back()      | 删除容器最后一个元素（无返回值，仅删除，容器非空时有效）           |
| erase(pos)      | 删除迭代器 pos 位置的元素，返回下一个元素的迭代器            |
| erase(beg, end) | 删除 [beg, end) 区间的元素，返回下一个元素的迭代器        |
| clear()         | 删除容器中所有元素（size() 变为 0，capacity() 可能不变） |
| **示例代码**：       |                                        |

```cpp
vector<int> vec{1,2,3,4,5};
vec.pop_back(); // 删除最后一个元素，vec: [1,2,3,4]
// 删除第二个元素（索引1）
auto it = vec.erase(vec.begin()+1); // it指向3，vec: [1,3,4]
// 删除区间[begin(), it)（即删除1）
vec.erase(vec.begin(), it); // vec: [4]
vec.clear(); // 清空所有元素，size=0，capacity仍为原容量
```

#### （3）调整大小与交换

| 函数             | 功能描述                                          |
| -------------- | --------------------------------------------- |
| resize(n)      | 调整容器大小为 n：n>原 size 则补默认初始化元素，n<原 size 则删除多余元素 |
| resize(n, val) | 调整容器大小为 n：新增元素初始值为 val                        |
| swap(v2)       | 交换当前容器与 v2 的所有元素（size、capacity、元素值均交换，效率高）    |
| **示例代码**：      |                                               |

```cpp
vector<int> vec{1,2,3};
vec.resize(5); // 扩容到5，新增元素默认值0，vec: [1,2,3,0,0]
vec.resize(2); // 缩容到2，删除多余元素，vec: [1,2]
vec.resize(4, 9); // 扩容到4，新增元素为9，vec: [1,2,9,9]
vector<int> vec2{88,99};
vec.swap(vec2); // 交换后：vec=[88,99]，vec2=[1,2,9,9]
```

### 4. 迭代器相关函数

迭代器用于遍历容器，支持正向、逆向、常量遍历：
| 函数 | 功能描述 |
|---------------|--------------------------------------------------------------------------|
| begin() | 返回指向第一个元素的正向迭代器（可修改元素） |
| end() | 返回指向最后一个元素之后位置的正向迭代器（不指向有效元素） |
| rbegin() | 返回指向最后一个元素的逆向迭代器（从后往前遍历） |
| rend() | 返回指向第一个元素之前位置的逆向迭代器 |
| cbegin() | 常量正向迭代器（C++11+，不可修改元素） |
| cend() | 常量正向结束迭代器（C++11+） |
| crbegin() | 常量逆向迭代器（C++11+） |
| crend() | 常量逆向结束迭代器（C++11+） |
**示例代码**：

```cpp
vector<int> vec{1,2,3,4,5};
// 正向遍历
for (auto it = vec.begin(); it != vec.end(); ++it) {
 cout << *it << " "; // 输出1 2 3 4 5
}
// 逆向遍历
for (auto it = vec.rbegin(); it != vec.rend(); ++it) {
 cout << *it << " "; // 输出5 4 3 2 1
}
// 常量迭代器（不可修改元素）
for (auto it = vec.cbegin(); it != vec.cend(); ++it) {
 // *it = 10; // 编译错误，常量迭代器不可修改
 cout << *it << " ";
}
```

## 四、关键注意事项

### 1. 迭代器失效场景

当 vector 进行以下操作时，可能导致迭代器失效，需重新获取迭代器：

- `insert`/`emplace` 导致容器扩容（capacity 变化）：所有迭代器、指针、引用失效；
- `erase` 删除元素：删除位置后的迭代器、指针、引用失效；
- `resize`/`reserve`/`shrink_to_fit` 导致扩容/缩容：所有迭代器、指针、引用失效；
- `clear()`：所有迭代器失效（但容器本身仍可用）。
  **修复示例**：
  
  ```cpp
  vector<int> vec{1,2,3,4};
  auto it = vec.begin() + 2; // 指向3
  // erase后it失效，需重新获取
  it = vec.erase(it); // it现在指向4
  ```
  
  ### 2. 边界检查
- `at()` 函数带边界检查，越界抛 `std::out_of_range` 异常，适合对安全性要求高的场景；
- `[]` 运算符无边界检查，效率更高，但需手动确保索引 `0 ≤ index < size()`，否则触发未定义行为（崩溃）。
  
  ### 3. 效率优化
- `emplace_back` 比 `push_back` 效率高：直接在容器末尾构造元素，避免临时对象的拷贝/移动（尤其适合自定义类型）；
- `reserve(n)` 预分配空间：减少扩容次数（vector 扩容时会重新分配内存、拷贝元素，开销大）；
- 批量操作优先用 `insert`/`assign`，而非循环 `push_back`，减少迭代器失效和扩容次数。
  
  ### 4. 非规则二维 vector
  
  每行列数可不同，需通过 `a[i].size()` 逐行获取列数，不能直接依赖 `a[0].size()`（可能导致越界或错误）。
  
  ### 5. 扩容机制
  
  vector 扩容时通常按“2倍”或“1.5倍”规则分配新内存（不同编译器实现不同），扩容后原内存释放，所有迭代器失效。通过 `reserve()` 预分配足够空间可避免频繁扩容。
  
  ### 6. 内存释放
- `clear()` 仅清空元素（size=0），不释放容量（capacity 不变）；
- `shrink_to_fit()` 可请求释放多余容量（非强制，编译器可能忽略）；
- 彻底释放内存：可通过“临时对象交换”：
  
  ```cpp
  vector<int> vec{1,2,3};
  // 临时vector与vec交换，临时对象析构时释放内存
  vector<int>().swap(vec); 
  // 此时vec.size()=0，capacity()=0
  ```
