# C语言动态内存分配详解

## **概述**

动态内存分配允许程序在运行时申请和释放内存，这提供了更大的灵活性。与静态内存分配（编译时确定大小）不同，动态内存的大小可以在程序执行过程中改变。

## **核心知识点**

### **<font color="#ee4c2e">为什么需要动态内存分配？</font>**

- **静态分配的局限**：数组大小必须在编译时确定，无法应对运行时才知道数据量的情况。
- **动态分配的优点**：根据实际需求分配内存，避免空间浪费或不足。

### **<font color="#209fff">动态内存管理函数</font>**

这些函数在`<stdlib.h>`头文件中声明。

## **函数详解与示例**

### **1. malloc() - 内存分配**

```c
void* malloc(size_t size);
```

- **功能**：分配指定字节数的未初始化内存块
- **参数**：`size` - 需要分配的字节数
- **返回值**：成功返回指向分配内存的指针，失败返回`NULL`

<font color="#32833a">**备注**：分配的内存不会被初始化，内容为随机值。</font>

**示例**：

```c
int *ptr = (int*)malloc(10 * sizeof(int));  // 分配10个整数的空间
```

### **2. calloc() - 清零分配**

```c
void* calloc(size_t num, size_t size);
```

- **功能**：分配指定数量、指定大小的内存块，并初始化为0
- **参数**：
  - `num` - 元素数量
  - `size` - 每个元素的大小（字节）
- **返回值**：成功返回指向分配内存的指针，失败返回`NULL`

**示例**：

```c
int *ptr = (int*)calloc(10, sizeof(int));  // 分配并初始化为0
```

### **3. realloc() - 重新分配**

```c
void* realloc(void* ptr, size_t new_size);
```

- **功能**：调整已分配内存块的大小
- **参数**：
  - `ptr` - 指向之前分配的内存块的指针
  - `new_size` - 新的字节数
- **返回值**：成功返回指向重新分配内存的指针，失败返回`NULL`

<font color="#32833a">**注意**：如果`ptr`为`NULL`，`realloc()`等价于`malloc(new_size)`</font>

### **4. free() - 释放内存**

```c
void free(void* ptr);
```

- **功能**：释放之前动态分配的内存
- **参数**：`ptr` - 指向要释放的内存块的指针
- **返回值**：无

<font color="#ee4c2e">**重点**：每次`malloc`、`calloc`或`realloc`后，必须对应调用`free()`</font>

## **<font color="#ee4c2e">常见错误与注意事项</font>**

### **1. 内存泄漏**

```c
void memory_leak() {
    int *ptr = (int*)malloc(100 * sizeof(int));
    // 忘记调用 free(ptr)
}
```

### **2. 野指针**

```c
int *ptr = (int*)malloc(sizeof(int));
free(ptr);
*ptr = 10;  // 错误：使用已释放的内存
```

### **3. 内存分配失败检查**

```c
int *ptr = (int*)malloc(1000000000 * sizeof(int));
if (ptr == NULL) {
    printf("内存分配失败！\n");
    exit(1);
}
```

### **4. 使用示例模式**

```c
// 分配
int *arr = (int*)malloc(n * sizeof(int));
if (arr == NULL) {
    // 错误处理
}

// 使用
for (int i = 0; i < n; i++) {
    arr[i] = i * 2;
}

// 释放
free(arr);
arr = NULL;  // 避免野指针
```

## **<font color="#209fff">相关函数列表</font>**

| 函数          | 参数                 | 功能描述              |
| ----------- | ------------------ | ----------------- |
| **malloc**  | `size_t size`      | 分配指定字节数的未初始化内存    |
| **calloc**  | `size_t num`       | 分配指定数量元素的内存并初始化为0 |
|             | `size_t size`      | 每个元素的大小（字节）       |
| **realloc** | `void* ptr`        | 指向已分配内存的指针        |
|             | `size_t new_size`  | 新的内存大小（字节）        |
| **free**    | `void* ptr`        | 释放动态分配的内存         |
| **memset**  | `void* ptr`        | 将内存块填充为指定值        |
|             | `int value`        | 要设置的值             |
|             | `size_t num`       | 要设置的字节数           |
| **memcpy**  | `void* dest`       | 目标内存地址            |
|             | `const void* src`  | 源内存地址             |
|             | `size_t num`       | 要复制的字节数           |
| **memmove** | `void* dest`       | 目标内存地址            |
|             | `const void* src`  | 源内存地址             |
|             | `size_t num`       | 要移动的字节数           |
| **memcmp**  | `const void* ptr1` | 第一个内存块的指针         |
|             | `const void* ptr2` | 第二个内存块的指针         |
|             | `size_t num`       | 要比较的字节数           |

## **<font color="#9221ff">实用技巧</font>**

### **1. 类型安全的分配**

```c
// 推荐
int *arr = malloc(10 * sizeof(*arr));

// 不推荐
int *arr = malloc(10 * sizeof(int));
```

### **2. 多维数组动态分配**

```c
// 分配3行4列的二维数组
int **matrix = (int**)malloc(3 * sizeof(int*));
for (int i = 0; i < 3; i++) {
    matrix[i] = (int*)malloc(4 * sizeof(int));
}

// 释放
for (int i = 0; i < 3; i++) {
    free(matrix[i]);
}
free(matrix);
```

## **总结**

<font color="#ee4c2e">动态内存管理是C语言编程中的重要技能</font>。正确使用`malloc`、`calloc`、`realloc`和`free`可以创建灵活高效的程序，但必须注意内存泄漏、野指针等问题。始终检查分配是否成功，并在使用后及时释放内存。
