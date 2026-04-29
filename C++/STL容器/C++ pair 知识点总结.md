# C\+\+ pair 知识点总结

## 1\. 基本概念

- `pair` 是 C\+\+ STL 中的**模板类**，用于将**两个值**组合成一个单元

- 头文件：``#include <utility>``（使用 `map` 时会自动包含）

- 常用来存储键值对、坐标、两个相关变量等

## 2\. 定义与初始化

```cpp
// 1. 默认构造
pair<int, string> p1;

// 2. 直接赋值
pair<int, string> p2(1, "hello");

// 3. 拷贝构造
pair<int, string> p3(p2);

// 4. make_pair 自动推导类型
auto p4 = make_pair(2, "world");
```

## 3\. 访问成员

- `first`：第一个元素

- `second`：第二个元素

```cpp
p2.first = 10;
p2.second = "hi";
cout << p2.first << " " << p2.second << endl;
```

## 4\. 常用操作

### 赋值

```cpp
p1 = p2;
```

### 比较运算

按 `first` 优先比较，`first` 相等再比较 `second`
支持：`==`、`!=`、`<`、`<=`、`>`、`>=`

### 交换

```cpp
swap(p1, p2);
// 或
p1.swap(p2);
```

## 5\. 常见用法

- 配合 `vector` 存多组二元数据
  
  ```cpp
  vector<pair<int, int>> vec;
  vec.emplace_back(1, 2);
  vec.push_back({3, 4});
  ```

- 遍历
  
  ```cpp
  for (auto &p : vec) {
      cout << p.first << " " << p.second << endl;
  }
  ```

- 作为 `map` 的元素类型
  
  ```cpp
  map<int, string> mp;
  mp.insert({1, "a"});
  // mp 中每个元素都是 pair<const int, string>
  ```

## 6\. 简化写法（C\+\+11\+）

```cpp
// 结构化绑定（C++17）
auto [x, y] = p2;
```
