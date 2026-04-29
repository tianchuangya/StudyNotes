### map / unordered_map去重

优点：计数加去重一起做



1、unordered_map（更快，无序）

优点：不改变原数组顺序

```cpp
unordered_map<string, int> cnt;
for (auto &s : arr) cnt[s]++;
```

2、map（有序，稍慢）

优点：自动排序

```cpp
map<string, int> cnt;
for (auto &s : arr) cnt[s]++;
```


