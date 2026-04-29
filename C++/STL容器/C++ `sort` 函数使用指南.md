你说得对！我应该使用锚点链接。让我修正一下：

# C++ `sort` 函数使用指南

## 📋 目录

- [基本用法](#基本用法)
- [自定义排序规则](#自定义排序规则)
- [结构体排序](#结构体排序)
- [字符串排序](#字符串排序)
- [pair-排序](#pair-排序)
- [数组排序](#数组排序)
- [部分排序](#部分排序)
- [性能与技巧](#性能与技巧)

## 📦 <span id="基本用法">基本用法</span>

### 包含头文件

```cpp
#include <algorithm>  // sort函数
#include <vector>     // 通常配合vector使用
#include <functional> // greater, less等
```

### 升序排序（默认）

```cpp
vector<int> nums = {5, 2, 8, 1, 3};
sort(nums.begin(), nums.end());  // {1, 2, 3, 5, 8}
```

### 降序排序

```cpp
// 方法1：使用greater<>
sort(nums.begin(), nums.end(), greater<int>());  // {8, 5, 3, 2, 1}

// 方法2：使用Lambda表达式
sort(nums.begin(), nums.end(), [](int a, int b) {
    return a > b;  // 降序
});
```

[返回目录](#目录)

## 🎯 <span id="自定义排序规则">自定义排序规则</span>

### 比较函数

```cpp
// 按绝对值排序
bool cmp_abs(int a, int b) {
    return abs(a) < abs(b);  // 按绝对值升序
}

vector<int> nums = {-5, 2, -8, 1, 3};
sort(nums.begin(), nums.end(), cmp_abs);  // {1, 2, 3, -5, -8}
```

### Lambda 表达式（推荐）

```cpp
vector<int> nums = {51, 23, 18, 42, 37};

// 按个位数排序
sort(nums.begin(), nums.end(), [](int a, int b) {
    return a % 10 < b % 10;  // 比较个位数
});
// 结果：{51, 42, 23, 37, 18}（个位数：1,2,3,7,8）
```

[返回目录](#目录)

## 🏗️ <span id="结构体排序">结构体排序</span>

### 方法1：重载 `<` 运算符（最简洁）

```cpp
struct Student {
    string name;
    int score;
    int id;

    // 重载 < 运算符
    bool operator<(const Student& other) const {
        if (score != other.score)
            return score > other.score;  // 成绩降序
        return id < other.id;            // id升序
    }
};

vector<Student> students;
sort(students.begin(), students.end());  // 直接使用
```

### 方法2：Lambda 表达式

```cpp
struct Student {
    string name;
    int score;
};

vector<Student> students;
sort(students.begin(), students.end(), [](const Student& a, const Student& b) {
    if (a.score != b.score)
        return a.score > b.score;  // 成绩降序
    return a.name < b.name;        // 姓名升序
});
```

[返回目录](#目录)

## 🔤 <span id="字符串排序">字符串排序</span>

### 按长度排序

```cpp
vector<string> words = {"apple", "banana", "cat", "dog", "elephant"};

// 按长度从小到大
sort(words.begin(), words.end(), [](const string& a, const string& b) {
    return a.length() < b.length();
});
// 结果：{"cat", "dog", "apple", "banana", "elephant"}
```

### 按字典序降序

```cpp
vector<string> words = {"apple", "banana", "cat"};
sort(words.begin(), words.end(), greater<string>());
// 结果：{"cat", "banana", "apple"}
```

[返回目录](#目录)

## 🤝 <span id="pair-排序">pair 排序</span>

### pair 默认排序规则

```cpp
vector<pair<int, string>> pairs = {{3, "Alice"}, {1, "Bob"}, {2, "Charlie"}};

// pair默认：先按first，相同再按second
sort(pairs.begin(), pairs.end());
// 结果：{{1, "Bob"}, {2, "Charlie"}, {3, "Alice"}}
```

### 自定义 pair 排序

```cpp
vector<pair<int, int>> points = {{1, 3}, {2, 1}, {1, 1}};

// 先按y坐标，再按x坐标
sort(points.begin(), points.end(), [](const pair<int,int>& a, const pair<int,int>& b) {
    if (a.second != b.second) 
        return a.second < b.second;  // 先按y
    return a.first < b.first;        // 再按x
});
// 结果：{{1, 1}, {2, 1}, {1, 3}}
```

[返回目录](#目录)

## 🔢 <span id="数组排序">数组排序</span>

```cpp
int arr[] = {5, 2, 8, 1, 3};
int n = sizeof(arr) / sizeof(arr[0]);

// 升序
sort(arr, arr + n);

// 降序
sort(arr, arr + n, greater<int>());
```

[返回目录](#目录)

## 📊 <span id="部分排序">部分排序</span>

### `partial_sort` - 部分排序

```cpp
vector<int> nums = {5, 2, 8, 1, 3, 6, 4, 7};

// 将最小的3个元素放在前3个位置
partial_sort(nums.begin(), nums.begin() + 3, nums.end());
// 结果：{1, 2, 3, ...}（前3个是最小的3个）
```

### `nth_element` - 第k小元素

```cpp
vector<int> nums = {5, 2, 8, 1, 3};

// 将第3小的元素放在索引2的位置
nth_element(nums.begin(), nums.begin() + 2, nums.end());
// nums[2] = 3（第3小的元素）
```

[返回目录](#目录)

## ⚡ <span id="性能与技巧">性能与技巧</span>

### 时间复杂度比较

| 函数               | 时间复杂度                    | 说明        |
| ---------------- | ------------------------ | --------- |
| `sort()`         | O(n log n)               | 快速排序      |
| `stable_sort()`  | O(n log n) 或 O(n log² n) | 归并排序      |
| `partial_sort()` | O(n log k)               | k为部分排序元素数 |
| `nth_element()`  | O(n)                     | 选择算法      |

### 稳定排序

```cpp
struct Item {
    string name;
    int value;
    int order;  // 输入顺序
};

vector<Item> items;

// stable_sort保持相等元素的原始顺序
stable_sort(items.begin(), items.end(), [](const Item& a, const Item& b) {
    return a.value < b.value;  // 相同value保持输入顺序
});
```

### 注意事项

```cpp
// ✅ 正确：比较函数应严格弱序
bool good_cmp(int a, int b) {
    return a < b;  // a == b时返回false
}

// ❌ 错误：比较函数不一致
bool bad_cmp(int a, int b) {
    return a <= b;  // a == b时返回true，错误！
}

// ✅ 使用引用提高效率（特别是大对象）
bool cmp_large(const BigObject& a, const BigObject& b) {
    return a.size < b.size;
}
```

[返回目录](#目录)

## 📝 快速参考表

| 需求    | 代码示例                                            |
| ----- | ----------------------------------------------- |
| 升序    | `sort(v.begin(), v.end())`                      |
| 降序    | `sort(v.begin(), v.end(), greater<int>())`      |
| 自定义规则 | `sort(v.begin(), v.end(), [](a,b){return 条件;})` |
| 结构体排序 | 重载 `<` 运算符                                      |
| 稳定排序  | `stable_sort(v.begin(), v.end(), cmp)`          |
| 部分排序  | `partial_sort(v.begin(), v.begin()+k, v.end())` |

## 💡 最佳实践

1. **优先使用Lambda表达式**，代码更清晰
2. **大对象使用const引用**，避免复制
3. **复杂排序规则**建议写在结构体内部（重载运算符）
4. **保持比较函数的一致性**，避免未定义行为
5. **考虑使用稳定排序**当需要保持相等元素的原始顺序时

[返回目录](#目录)
