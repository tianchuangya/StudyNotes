```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

// 1. 求 next 数组
vector<int> getNext(string p) {
    int n = p.size();
    vector<int> next(n, 0);
    int j = 0;
    for (int i = 1; i < n; i++) {
        while (j > 0 && p[i] != p[j]) {
            j = next[j - 1];
        }
        if (p[i] == p[j]) {
            j++;
        }
        next[i] = j;
    }
    return next;
}

// 2. KMP 匹配
int kmp(string s, string p) {
    vector<int> next = getNext(p);
    int n = s.size();
    int m = p.size();
    int j = 0;

    for (int i = 0; i < n; i++) {
        // 不匹配就回退
        while (j > 0 && s[i] != p[j]) {
            j = next[j - 1];
        }
        // 匹配就 j++
        if (s[i] == p[j]) {
            j++;
        }
        // 全部匹配成功
        if (j == m) {
            return i - m + 1; // 注意：这是返回第一次出现的位置一定要-m+1
        }
    }

    return -1; // 没找到
}

// 测试
int main() {
    string s = "ababcabcd";
    string p = "abc";
    cout << kmp(s, p) << endl;
    return 0;
}
```

易错点：

1. KMP函数中：return返回位置忘记减长度 : `return i - m + 1;`
2. 回退要用 while 不能用 if ：`for(int i = 1; i < m; i++)`
3. 回退位置必须是 j-1 :`j = next[j];`
4. 匹配时比较 s [i] 和 p [j]，别搞反 :`s[i] != p[j]`
5. getnext()函数中，for循环中i赋值成1 : `for (int i = 1; i < n; i++)`

    
