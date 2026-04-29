#include<iostream>
#include<string>
#include<vector>
#include<algorithm>
#include<cmath>
using namespace std;

vector<int> add(vector<int>a, vector<int>b) {
	if (a.size() < b.size())return add(b, a);
	int jw = 0;
	vector<int>c;
	for (int step = 0; step <= a.size() - 1 || jw > 0; step++) {
		int temp = 0;
		if (step <= a.size() - 1)temp += a[step];
		if (step <= b.size() - 1)temp += b[step];
		temp += jw;
		jw = temp / 10;
		temp %= 10;
		c.push_back(temp);
	}
	return c;
}


int main() {
	int n;
	cin >> n;
	vector<int>dp1 = { 1 };
	vector<int>dp2 = { 2 };
	vector<int>dp;
    if(n==1){
        cout<<1<<endl;
        return 0;
    }
    if(n==2){
        cout<<2<<endl;
        return 0;
    }
	for (int step = 3; step <= n; step++) {
		dp = add(dp1, dp2);
		dp1 = dp2;
		dp2 = dp;
	}
	for (int i = dp.size() - 1; i >= 0; --i) {
		cout << dp[i];
	}
    cout<<endl;
}

