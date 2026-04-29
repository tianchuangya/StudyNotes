#include<iostream>
#include<vector>
bool isprime(int n);
using namespace std;
int main()
{
	int n=1e6;       //输入n 表示从1-n范围的素数判断
	double time1 = clock();
	long long count = 0;
	for (int i = 1; i <= n; i++)
	{
		if (isprime(i)) {
			count++;
			//cout << i << " ";
		}
	}
	double time2 = clock();
	printf("times need %lfms the prime have %lld", time2 - time1,count);
	return 0;
}

bool isprime(int n) {
	if (n == 1)return 0;
	if (n == 2)return 1;
	for (int i = 2; i <= n / i; i++) //i<=n/i 防止溢出而做出的优化 
	{
		if (n % i == 0)return 0;
	}
	return 1;
}
