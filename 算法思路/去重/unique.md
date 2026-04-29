**`unique`** 函数是 C++ 标准模板库（STL）中的一个实用函数，用于去除容器或数组中相邻的重复元素。它不会真正删除元素，而是<u><span>将重复的元素移动到容器的末尾，并返回去重后的尾地址</span></u>。

使用前提：只能对<u>排序</u>好的数组使用，并且你不在乎会修改数据顺序

例子：

```cpp
vector<int> b = {100, -5, 100, 9999, 0, -5};
sort(b.begin(), b.end());          //  排序
b.erase(unique(b.begin(), b.end()), b.end()); //  去重
```

函数实现代码：

```cpp
// 功能：原地去重（只保留相邻不重复）
// 返回：去重后新的结束位置迭代器
template <typename Iter>
Iter my_unique(Iter begin, Iter end) {
    if (begin == end) return end; // 空数组直接返回
    
    Iter last = begin; // 慢指针：记录最后一个不重复元素
    
    // 快指针：遍历整个数组
    for (auto it = begin + 1; it != end; ++it) {
        // 发现不重复元素
        if (*it != *last) {
            ++last;        // 慢指针前进
            *last = *it;   // 覆盖赋值（核心！不删除、不移位）
        }
    }
    
    return last + 1; // 返回新结尾
}
```


