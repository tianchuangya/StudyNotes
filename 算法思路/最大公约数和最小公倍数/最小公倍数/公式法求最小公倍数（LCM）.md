# **公式法求最小公倍数（LCM）**

### **一、核心概念**：

最小公倍数（Least Common Multiple，LCM）是能被两个（或多个）整数同时整除的最小正整数。求LCM的核心公式基于<span style="color:#ee4c2e">**最大公约数（GCD）与LCM的关联定理**</span>，也是工程中最实用的公式法，具体如下：

#### 1. 核心公式（两数版）

对于任意非零整数 $a、b$，满足：

$\text{lcm}(a,b) = \frac{|a \times b|}{\gcd(a,b)}$

代码示例：

```cpp
int lcm(int a, int b) {
	if (a == 0 && b == 0) return 0; // 边界：两数均为0，无LCM
	int c = gcd(a, b);
	// 先除后乘，避免a*b溢出
	return (abs(c) / g) * abs(b);
}
```

#### 2. 扩展公式（多数版）

对于 $n$ 个非零整数 $a_1,a_2,\dots,a_n$，需逐步计算：
$\text{lcm}(a_1,a_2,\dots,a_n) = \text{lcm}(\text{lcm}(a_1,a_2),a_3,\dots,a_n)$

<span style="color:#32833a">核心逻辑就是以第一个数为初始值，遍历剩余所有数，两两递推求 LCM，本质是复用 “两数 LCM 公式” 逐步收敛到最终结果。</span>

代码示例：

```cpp

int lcm(int a, int b) {
	if (a == 0 && b == 0) return 0; // 边界：两数均为0，无LCM
	int c = gcd(a, b);
	// 先除后乘，避免a*b溢出
	return (abs(c) / g) * abs(b);
}

int lcms(int arr[], int n) {
    int res = arr[0];  // 初始值取第一个数
    for (int i = 1; i < n; i++) {  // 遍历剩余数
        res = lcm(res, arr[i]);      // 两两递推求LCM
    }
    return res;
}
```

### **二、举例说明**：

#### 例1：求<span style="color:#9221ff">lcm(12, 18)</span>

1. 先求 $\gcd(12,18)=6$；

2. 代入优化公式：$\text{lcm}(12,18) = \frac{|12|}{6} × |18| = 2 × 18 = 36$。
   
   #### 例2：求<span style="color:#9221ff">lcm(-24, 30)</span>

3. 取绝对值后求 $\gcd(24,30)=6$；

4. 计算：$\text{lcm}(-24,30) = \frac{24}{6} × 30 = 4 × 30 = 120$。
   
   #### 例3：避免溢出（求<span style="color:#9221ff">lcm(1000000000, 500000000)</span>）

5. 若直接计算 $10^9 × 5×10^8 = 5×10^{17}$，超出int范围（int最大约2×10^9）；

6. 优化计算：$\gcd(10^9,5×10^8)=5×10^8$ → $\frac{10^9}{5×10^8} × 5×10^8 = 2 × 5×10^8 = 10^9$。
   
   #### 例4：求多數<span style="color:#9221ff">lcm(4, 6, 8)</span>

7. 先求 $\text{lcm}(4,6) = \frac{4}{2}×6=12$；

8. 再求 $\text{lcm}(12,8) = \frac{12}{4}×8=24$；
   最终结果：$\text{lcm}(4,6,8)=24$。
   
   ### **三、代码实现**：
   
   ```cpp
   #include <cstdlib> // 包含abs函数
   // 先实现欧几里得算法求GCD（迭代版，兼容负数）
   int gcd(int a, int b) {
   	a = abs(a);
   	b = abs(b);
   	while (b != 0) {
   		int c = a % b;
   		a = b;
   		b = c;
   	}
   	return a;
   }
   // 公式法求两数的LCM（优化溢出）
   int lcm(int a, int b) {
   	if (a == 0 && b == 0) return 0; // 边界：两数均为0，无LCM
   	int c = gcd(a, b);
   	// 先除后乘，避免a*b溢出
   	return (abs(c) / g) * abs(b);
   }
   // 扩展：公式法求多个数的LCM
   int lcm_multi(int nums[], int n) {
   	if (n <= 0) return 0;
   	int result = nums[0];
   	for (int i = 1; i < n; ++i) {
   		result = lcm(result, nums[i]);
   		if (result == 0) break; // 出现0且另一数非0，LCM为0
   	}
   	return result;
   }
   // 测试示例
   int main() {
   	// 两数LCM
   	int l1 = lcm(12, 18); // 输出36
   	int l2 = lcm(-24, 30); // 输出120
   	// 多數LCM
   	int arr[] = { 4, 6, 8 };
   	int l3 = lcm_multi(arr, 3); // 输出24
   	return 0;
   }
   ```
   
   <span style="color:#32833a">**备注1**：`return a*b/gcd(a,b)`）未做溢出优化，当a、b较大时（如1e9级别）会出错，上述代码的`“先除后乘”`是工程必备优化；
   **备注2**：若需处理更大范围的整数（如64位），需将函数参数、返回值改为`long long`类型，逻辑不变；
   **备注3**：多數LCM的核心是`“两两递推”`，本质仍是复用两数LCM的核心公式，无需额外推导新公式。</span>


