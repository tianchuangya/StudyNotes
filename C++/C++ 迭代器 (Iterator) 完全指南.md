## 

# C++ 迭代器 (Iterator) 完全指南

## 1. 迭代器概述

迭代器是一种用于遍历容器（如 `vector`、`list`、`map` 等）中元素的对象，它提供了类似指针的操作（如 `++`、`*`），但行为更通用，是**泛型编程**的核心。

- **核心思想**：将**算法**与**容器**解耦。算法通过迭代器操作数据，无需关心容器的具体类型。
- <span style="color: #209fff">迭代器</span> 是**行为像指针的对象**，但比指针更安全、更抽象。
- **核心价值**：统一所有容器的遍历接口，让同一套算法能适配任意容器。
  
  ## 2. 迭代器的分类与能力
  
  迭代器按操作能力分为五类，层次递进：
  
  | 类别                                                                                                            | 支持操作                             | 特点                | 示例容器                             |
  |:------------------------------------------------------------------------------------------------------------- |:-------------------------------- |:----------------- |:-------------------------------- |
  | <span style="color: #ee4c2e">**输入迭代器**</span>                                                                 | `++`, `==`, `!=`, `*` (只读)       | 单遍扫描，只读，不可重复遍历    | `istream_iterator`               |
  | <span style="color: #ee4c2e">**输出迭代器**</span>                                                                 | `++`, `*` (只写)                   | 单遍扫描，只写，不可重复遍历    | `ostream_iterator`               |
  | <span style="color: #ee4c2e">**前向迭代器**</span>                                                                 | 输入迭代器 + 多遍扫描                     | 可多次读写，只能向前移动      | `forward_list`, `unordered_map`  |
  | <span style="color: #ee4c2e">**双向迭代器**</span>                                                                 | 前向迭代器 + `--`                     | 可前后移动             | `list`, `map`, `set`             |
  | <span style="color: #ee4c2e">随机访问迭代器</span><span style="color: #32833a">**<br>注意**：原生指针可视为最高级的随机访问迭代器。</span> | 双向迭代器 + `+`, `-`, `[]`, `<`, `>` | 支持跳跃式访问，时间复杂度O(1) | `vector`, `deque`, `array`, 原生指针 |
  | <span style="color: #ee4c2e">**重要**：算法对迭代器有最低要求，使用算法前必须确保传入的迭代器满足其所需的最低类别。</span>                             |                                  |                   |                                  |
  | <span style="color: #ee4c2e">例：`std::sort` 要求**随机访问迭代器**，不能用于 `list`/`map`。</span>                            |                                  |                   |                                  |



## 4. 迭代器的基本操作

以下操作适用于所有迭代器（具体支持程度取决于分类）：

| 操作                      | 说明                           | 适用迭代器类型       |
|:----------------------- |:---------------------------- |:------------- |
| `*iter`                 | 解引用，返回元素引用                   | 所有（输出迭代器只能赋值） |
| `iter->member`          | 访问元素成员（等价于 `(*iter).member`） | 前向及以上         |
| `++iter` / `iter++`     | 前进到下一个元素                     | 所有            |
| `--iter` / `iter--`     | 回退到上一个元素                     | 双向及以上         |
| `iter1 == iter2`        | 判断是否相等                       | 输入及以上         |
| `iter1 != iter2`        | 判断是否不等                       | 输入及以上         |
| `iter + n` / `iter - n` | 前进 / 回退 n 个位置                | 随机访问          |
| `iter1 - iter2`         | 计算两个迭代器间的距离                  | 随机访问          |
| `iter[n]`               | 访问第 n 个元素（等价于 `*(iter + n)`） | 随机访问          |
| `<`, `>`, `<=`, `>=`    | 比较位置前后                       | 随机访问          |

**最佳实践**：优先使用前置自增 `++it`，效率高于后置 `it++`（避免临时对象拷贝）。

## 5. 迭代器失效

**易错点**：迭代器失效是 C++ 中最常见的陷阱之一。容器在修改结构时（插入、删除、重分配）可能导致已有迭代器无效，继续使用会导致未定义行为（崩溃或数据错误）。

### 常见容器的失效场景

| 容器                                | 操作                             | 失效情况                                            |
|:--------------------------------- |:------------------------------ |:----------------------------------------------- |
| `vector` / `string`               | `insert()` / `push_back()`     | 如果导致内存重分配：所有迭代器、指针、引用失效。<br>如果未重分配：插入点之后的迭代器失效。 |
|                                   | `erase()`                      | 被删除元素及之后的所有迭代器失效。                               |
|                                   | `reserve()` / `resize()`       | 若容量改变，所有迭代器失效。                                  |
| `deque`                           | `insert()` 在首尾                 | 可能使所有迭代器失效。                                     |
|                                   | `erase()` 在首尾                  | 被删除元素及对端迭代器可能失效。                                |
|                                   | `push_front()` / `push_back()` | 插入点对面的迭代器可能失效。                                  |
| `list` / `forward_list`           | `insert()` / `erase()`         | 仅被删除的迭代器失效，其他迭代器、引用、指针保持有效。                     |
| `map` / `set`                     | `insert()` / `erase()`         | 仅被删除的迭代器失效，其他迭代器保持有效。                           |
| `unordered_map` / `unordered_set` | `insert()` / `erase()`         | 若发生 rehash：所有迭代器失效。<br>若未 rehash：仅被删除的迭代器失效。    |

**最佳实践**：在对容器进行修改（特别是 `vector`）后，应重新获取迭代器，或使用返回新迭代器的 `erase()` / `insert()` 函数。

```cpp
// 正确遍历并删除 vector 中的元素
std::vector<int> vec = {1, 2, 3, 4, 5};
for (auto it = vec.begin(); it != vec.end(); ) {
    if (*it % 2 == 0) {
        it = vec.erase(it); // erase 返回被删除元素的下一个有效迭代器
    } else {
        ++it;
    }
}
```

**补充易错点**：`range-for` 循环底层依赖迭代器，循环内修改容器（增删）会直接导致迭代器失效！

## 6. 迭代器适配器

标准库提供了一些迭代器适配器，用于生成特殊行为的迭代器：

| 适配器   | 作用                                                      | 头文件          |
|:----- |:------------------------------------------------------- |:------------ |
| 反向迭代器 | 使遍历方向相反（`rbegin()`/`rend()` 返回）                         | `<iterator>` |
| 插入迭代器 | 将赋值转换为插入操作（`back_inserter`、`front_inserter`、`inserter`） | `<iterator>` |
| 流迭代器  | 将输入 / 输出流视为容器（`istream_iterator`、`ostream_iterator`）    | `<iterator>` |
| 移动迭代器 | 解引用时返回右值引用（用于移动语义，`make_move_iterator`）                 | `<iterator>` |
| 边界迭代器 | C++20 `std::views` 迭代器，适配范围适配器                          | `<ranges>`   |

**举例**：`std::copy` 结合 `back_inserter` 可向容器末尾安全添加元素。

```cpp
#include <iterator>
#include <vector>
#include <algorithm>

std::vector<int> src = {1, 2, 3};
std::vector<int> dest;
std::copy(src.begin(), src.end(), std::back_inserter(dest)); // dest: [1, 2, 3]
```

## 7. 迭代器相关的辅助函数与技巧

| 函数 / 技巧                                     | 说明                                                        |
|:------------------------------------------- |:--------------------------------------------------------- |
| `std::advance(it, n)`                       | 将迭代器 `it` 前进 `n` 步。复杂度：随机访问为 O(1)，否则 O(n)。                |
| `std::distance(first, last)`                | 计算 `first` 到 `last` 的元素个数。非随机访问迭代器必须保证 `last` 可达 `first`。 |
| `std::next(it, n=1)` / `std::prev(it, n=1)` | 返回 `it` 前进 / 回退 `n` 步后的迭代器，不改变原迭代器（C++11）。                |
| `std::begin(arr)` / `std::end(arr)`         | 获取数组的起始和尾后迭代器，通用化获取容器的 `begin()`/`end()`。                 |
| `std::empty` / `std::size`                  | C++17 通用容器 / 数组判空、取大小。                                    |
| `using iterator_category`                   | 自定义迭代器必须定义嵌套类型，用于 traits 机制。                              |

**高危警告**：`distance` 用于非随机访问迭代器时，若 `last` 在 `first` 前面，会触发无限循环 / 未定义行为！

## 8. 常量迭代器与非常量迭代器

- **非常量迭代器（`iterator`）**：可读写元素。
- **常量迭代器（`const_iterator`）**：只读元素。

**易错点**：若容器本身是 `const`，则只能获得 `const_iterator`。若希望通过 `const` 引用修改元素，必须非常谨慎，应使用 `const_cast`，但通常不推荐。

C++17 新特性：`auto` 自动推导 + 非成员 `cbegin()`/`cend()`，可强制获取常量迭代器。

```cpp
void print(const std::vector<int>& vec) {
    // vec 是 const，只能使用 const_iterator
    for (auto it = vec.cbegin(); it != vec.cend(); ++it) {
        // *it = 0; // 错误！不能通过 const_iterator 修改
        std::cout << *it << " ";
    }
}
```

## 9. C++20 范围迭代器（Ranges）

C++20 核心扩展：`std::ranges` 迭代器，支持视图、惰性求值、管道操作，是现代 C++ 迭代器的升级。

- 无需手动管理 `begin`/`end`，直接操作容器范围。
- 支持 `filter`/`transform`/`reverse` 等惰性适配器。
- 兼容所有旧标准迭代器。

```cpp
#include <ranges>
#include <vector>
#include <iostream>

int main() {
    std::vector<int> v = {1,2,3,4,5};
    // 管道式迭代：过滤偶数 + 翻倍
    auto even_double = v | std::views::filter([](int x){return x%2==0;})
                         | std::views::transform([](int x){return x*2;});
    for (auto x : even_double) std::cout << x << " "; // 输出：4 8
}
```

## 10. 自定义迭代器

当编写自定义容器时，需要为其提供迭代器。实现一个随机访问迭代器通常需要满足以下要求：

1. 定义五个嵌套类型（`value_type`, `difference_type`, `pointer`, `reference`, `iterator_category`）。
2. 实现所有必要的操作符：`++`, `--`, `*`, `->`, `==`, `!=`, `+`, `-`, `[]`, `<`, `>` 等。
3. 可以从 `std::iterator_traits` 获取特性，C++17 后不再推荐继承 `std::iterator`。

```cpp
// 简化示例：一个简单的自定义迭代器骨架（C++17 风格）
class MyIterator {
public:
    using iterator_category = std::random_access_iterator_tag;
    using value_type = int;
    using difference_type = std::ptrdiff_t;
    using pointer = int*;
    using reference = int&;

    // 实现必要操作符...
    reference operator*() const { return *ptr; }
    MyIterator& operator++() { ++ptr; return *this; }
    bool operator==(const MyIterator& other) const = default; // C++20 默认比较
    // ... 其他操作符
private:
    int* ptr;
};
```

**提示**：为了简化，可以使用 Boost.Iterator 库，它提供了迭代器构建模板。  
**补充要求**：自定义迭代器必须满足迭代器概念，否则无法适配标准算法。

## 11. 迭代器安全与最佳实践

1. **绝不解引用尾后迭代器**：`end()`/`rend()` 不能 `*` / `->`。
2. **循环内不修改容器**：`range-for` 和普通循环中增删会失效。
3. **优先使用 `cbegin`/`cend`**：只读场景用常量迭代器更安全。
4. **失效后重新获取**：增删操作后不要复用旧迭代器。
5. **算法匹配迭代器类型**：`sort` 只用随机访问，`list` 用成员函数 `sort`。

---

## 相关函数列表

| 函数                         | 参数                                                                                         | 功能描述                                                             |
|:-------------------------- |:------------------------------------------------------------------------------------------ |:---------------------------------------------------------------- |
| `std::advance`             | `InputIt& it`<br>`Difference n`                                                            | 将迭代器 `it` 向前移动 `n` 步。若 `n` 为负，要求 `it` 是双向迭代器。                    |
| `std::distance`            | `InputIt first`<br>`InputIt last`                                                          | 返回从 `first` 到 `last` 的元素个数。若迭代器不是随机访问，则复杂度为 O(N)。                |
| `std::next`                | `ForwardIt it`<br>`typename iterator_traits<ForwardIt>::difference_type n = 1`             | 返回 `it` 前进 `n` 步后的迭代器，不修改 `it` 本身。                               |
| `std::prev`                | `BidirectionalIt it`<br>`typename iterator_traits<BidirectionalIt>::difference_type n = 1` | 返回 `it` 后退 `n` 步后的迭代器，不修改 `it` 本身。                               |
| `std::back_inserter`       | `Container& c`                                                                             | 创建一个 `std::back_insert_iterator`，对它的赋值操作会调用容器的 `push_back`。      |
| `std::front_inserter`      | `Container& c`                                                                             | 创建一个 `std::front_insert_iterator`，对它的赋值操作会调用容器的 `push_front`。    |
| `std::inserter`            | `Container& c`<br>`Container::iterator pos`                                                | 创建一个 `std::insert_iterator`，对它的赋值操作会调用容器的 `insert`，在 `pos` 之前插入。 |
| `std::make_move_iterator`  | `Iterator it`                                                                              | 将给定的迭代器转换为移动迭代器，解引用时返回右值引用（`value_type&&`）。                      |
| `std::begin`               | `Container& c`<br>`const Container& c`<br>`T (&arr)[N]`                                    | 返回指向容器或数组起始位置的迭代器。                                               |
| `std::end`                 | `Container& c`<br>`const Container& c`<br>`T (&arr)[N]`                                    | 返回指向容器或数组尾后位置的迭代器。                                               |
| `std::cbegin`              | `Container& c`<br>`const Container& c`                                                     | 返回指向容器起始位置的常量迭代器（C++11）。                                         |
| `std::cend`                | `Container& c`<br>`const Container& c`                                                     | 返回指向容器尾后位置的常量迭代器（C++11）。                                         |
| `std::rbegin`              | `Container& c`<br>`const Container& c`<br>`T (&arr)[N]`                                    | 返回指向容器或数组最后一个元素的反向迭代器。                                           |
| `std::rend`                | `Container& c`<br>`const Container& c`<br>`T (&arr)[N]`                                    | 返回指向容器或数组第一个元素前一个位置的反向迭代器。                                       |
| `std::crbegin`             | `Container& c`<br>`const Container& c`                                                     | 返回指向容器最后一个元素的常量反向迭代器（C++14）。                                     |
| `std::crend`               | `Container& c`<br>`const Container& c`                                                     | 返回指向容器第一个元素前一个位置的常量反向迭代器（C++14）。                                 |
| `std::size`/`std::empty`   | 容器 / 数组                                                                                    | C++17 通用取大小、判空（适配迭代器体系）。                                         |
| `std::ranges::begin`/`end` | C++20 范围                                                                                   | 适配范围视图的迭代器接口。                                                    |

---

# 本次补充的核心遗漏点（清单）

1. **C++17/20 新特性**
   
   - 常量反向迭代器 `crbegin`/`crend`
   - C++20 Ranges 范围迭代器（现代迭代器核心升级）
   - 默认比较运算符 `operator==(...) = default`

2. **高危易错点**
   
   - `range-for` 循环内修改容器 = 迭代器失效
   - `std::distance` 非随机访问迭代器的**无限循环风险**
   - 前置 `++it` 优于后置 `it++` 的效率原因

3. **知识点补全**
   
   - 迭代器分类的**严格层级关系**
   - 算法与迭代器类型的匹配规则（如 `sort` 要求随机访问）
   - 自定义迭代器 **C++17 标准写法**（弃用 `std::iterator`）
   - 迭代器通用最佳实践

4. **函数补全**
   
   - `std::size`/`std::empty`（C++17 迭代器配套工具）
   - C++20 Ranges 迭代器函数

5. **边界场景**
   
   - 尾后迭代器的严格使用规则
   - 只读场景强制使用 `const_iterator` 的规范
     
