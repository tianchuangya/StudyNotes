#include<iostream>
#include<vector>
#include<bitset>  // 包含bitset头文件
#include<ctime>    // 包含ctime头文件用于clock()
using namespace std;
const int max_nums =1e6+10;
bitset<max_nums> pri;  //创建一个素数标记数组 0为素数 1为非素数
int main()
{
	int n=1e6;       //输入n 表示从1-n范围的素数判断
	double time1 = clock();
	long long count = 0;
	for (int i = 2; i <= n/i; i++)// 因为一个质数必定是有小于等于它根号的数相乘而得,
	{							//我们对2 -n/i 每一个数进行倍数相加 
		if (!pri[i]) {			//必定会判断到n
			for (int j = i * i; j <= n; j += i)//标记每一个i的倍数
				pri[j] = 1;					//从i*i开始标记，因为2*i，
		}									//3*i, ..., (i-1)*i已经被更小的素数标记过了
	}	
	// 统计素数个数
	for (int i = 2; i <= n; i++)
	{
		if (!pri[i]) {
			//cout << i << " ";
			count++;
		}

	}
	double time2 = clock();
	printf("times need %lfms the prime have %lld", time2 - time1,count);
	return 0;
}


