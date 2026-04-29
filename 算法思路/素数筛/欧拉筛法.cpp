#include <iostream>
#include <vector>
#include <bitset> // 引入 bitset

using namespace std;

// 定义一个足够大的常量作为 bitset 的大小
// 假设我们处理的最大值不超过 10^7
const int MAX_N = 10000000;

/**
 * @brief 使用欧拉筛法（线性筛法）找出小于等于 n 的所有质数。
 *        使用 bitset 来优化内存占用。
 * @param n 筛选的上限。
 * @return 一个包含所有质数的 vector。
 */
vector<int> euler_sieve_with_bitset(int n) {
    // 使用 bitset 来标记数字是否为质数
    // bitset<MAX_N+1> is_prime;
    // bitset 的所有位在初始化时默认为 0 (false)
    // 我们需要将所有位先设为 1 (true)，表示初始时假设所有数都是质数
    bitset<MAX_N + 1> is_prime;
    is_prime.set(); // 将所有位设置为 1 (true)

    // 0 和 1 不是质数，将它们标记为 0 (false)
    is_prime.reset(0);
    is_prime.reset(1);

    // primes: 向量，用于存储我们已经找到的所有质数。
    vector<int> primes;

    // 从 2 开始遍历到 n。
    for (int i = 2; i <= n; ++i) {
        // 步骤 1: 如果 i 是质数 (is_prime[i] 的位为 1)
        if (is_prime.test(i)) { // 使用 test() 方法检查某位是否为 1
            // 将其加入到 primes 数组中。
            primes.push_back(i);
        }

        // 步骤 2: 用当前的数 i 去乘以 primes 数组中的每个质数 p_j，
        // 从而筛掉合数 i * p_j。
        for (int j = 0; j < primes.size() && i * primes[j] <= n; ++j) {
            // 标记 i * primes[j] 为合数 (将对应位设置为 0)
            is_prime.reset(i * primes[j]); // 使用 reset() 方法将某位设置为 0

            // 关键步骤：保证每个合数只被其最小质因数筛掉一次。
            if (i % primes[j] == 0) {
                break;
            }
        }
    }

    return primes;
}

// 主函数，用于测试
int main() {
    int n;
    cout << "请输入一个正整数 n: ";
    cin >> n;

    // 检查 n 是否超过了 bitset 的预设大小
    if (n > MAX_N) {
        cout << "输入的 n 超过了 bitset 的最大支持范围 " << MAX_N << endl;
        return 1;
    }

    vector<int> primes = euler_sieve_with_bitset(n);

    cout << "小于等于 " << n << " 的所有质数是: " << endl;
    for (size_t i = 0; i < primes.size(); ++i) {
        cout << primes[i] << " ";
        // 每输出 10 个质数换行，使格式更清晰
        if ((i + 1) % 10 == 0) {
            cout << endl;
        }
    }
    cout << endl;

    cout << "共有 " << primes.size() << " 个质数。" << endl;

    return 0;
}
