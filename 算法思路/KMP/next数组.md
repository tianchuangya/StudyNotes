```cpp
vector<int> getNext(string s) {
    int n = s.size();
    vector<int> next(n, 0);//这里表示开n个元素，并且每个元素都初始化为0
    for (int i = 1, j = 0; i < n; i++) {//     j：当前最长相等前缀后缀的长度
        // 不匹配就回退
        while (j > 0 && s[i] != s[j]) {
            j = next[j - 1];
        }//只要不匹配，就不停地往前回退（跳），直到找到一个能和 s [i] 配上的位置，或者实在配不上，直接退到 j=0，从头开始。

        // 匹配就加长
        if (s[i] == s[j]) {
            j++;
        }
        next[i] = j;
    }
    return next;
}
```

口诀：

- **匹配不上，就往前跳（回退）**
- **跳到能配上，或者跳到 0从新开始**
- 配上了 j 就 + 1
- next[i]=j


