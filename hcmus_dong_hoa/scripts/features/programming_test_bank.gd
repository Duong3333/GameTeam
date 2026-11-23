extends RefCounted
# Bo testcase offline cho cac cau CSLT co the chay tu dong.
# Sinh vien chi viet ham/ doan lenh duoc yeu cau; file nay them main() de goi thu.

const CASE_END := "@@CASE_END@@"

static func supports(question_id: String) -> bool:
	return _specs().has(question_id)

static func build_program(question_id: String, student_code: String) -> Dictionary:
	var all_specs := _specs()
	if not all_specs.has(question_id):
		return {}
	var spec: Dictionary = all_specs[question_id]
	var harness := str(spec["harness"])
	var source := """
#include <iostream>
#include <iomanip>
#include <cmath>
#include <algorithm>
using namespace std;
const int MAX = 100;

"""
	if question_id in ["CSLT_EXAM_002_Q01", "CSLT_EXAM_004_Q01"]:
		source += harness.replace("STUDENT_SNIPPET", student_code)
	else:
		source += student_code + "\n" + harness
	return {
		"source": source,
		"input": str(spec["input"]),
		"expected_cases": spec["expected_cases"].duplicate(),
		"question_id": question_id
	}

static func _specs() -> Dictionary:
	return {
		# De 1
		"CSLT_EXAM_001_Q02": {
			"input": "5\n10 3\n0 3\n10 5\n1 3\n20 4\n",
			"expected_cases": ["18", "0", "15", "0", "60", "18"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n, k; cin >> n >> k;
        cout << sumMultiples(n, k) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
    // Kiem tra tham so mac dinh k = 3 theo yeu cau de bai.
    cout << sumMultiples(10) << '\\n';
    cout << "@@CASE_END@@\\n" << flush;
}
"""
		},
		"CSLT_EXAM_001_Q04": {
			"input": "4\n5\n1 -2 3 0 4\n0\n4\n-1 -2 -3 -4\n3\n5 6 -1\n",
			"expected_cases": ["8 3", "0 0", "0 0", "11 2"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        int cnt = -1;
        long long sum = sumPositive(a, n, cnt);
        cout << sum << ' ' << cnt << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_001_Q05": {
			"input": "3\n3 3\n1 2 3\n2 2 2\n-1 -2 -3\n2 2\n-5 -1\n-2 -2\n2 3\n1 1 1\n2 2 2\n",
			"expected_cases": ["0", "1", "1"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int R, C; cin >> R >> C;
        int a[MAX][MAX] = {};
        for (int i = 0; i < R; ++i)
            for (int j = 0; j < C; ++j) cin >> a[i][j];
        cout << rowWithMaxSum(a, R, C) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		# De 2
		"CSLT_EXAM_002_Q01": {
			"input": "5\n3 3 3\n3 3 4\n3 4 5\n1 2 3\n2 2 3\n",
			"expected_cases": ["Tam giac deu", "Tam giac can", "Tam giac thuong", "Khong phai tam giac", "Tam giac can"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int a, b, c; cin >> a >> b >> c;
        STUDENT_SNIPPET
        cout << "\\n@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_002_Q02": {
			"input": "5\n12 18\n25 0\n0 7\n48 18\n1 1\n",
			"expected_cases": ["6", "25", "7", "6", "1"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int a, b; cin >> a >> b;
        cout << gcd(a, b) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_002_Q04": {
			"input": "4\n5 2\n1 2 3 4 5\n5 -1\n1 2 3 4 5\n4 0\n9 8 7 6\n5 8\n1 2 3 4 5\n",
			"expected_cases": ["4 5 1 2 3", "2 3 4 5 1", "9 8 7 6", "3 4 5 1 2"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n, k; cin >> n >> k;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        rotate(a, n, k);
        for (int i = 0; i < n; ++i) cout << a[i] << (i + 1 == n ? '\\n' : ' ');
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_002_Q05": {
			"input": "3\n2 4\n1 2 3 4\n6 8 10 12\n1 3\n2 4 6\n3 2\n1 3\n2 4\n6 8\n",
			"expected_cases": ["2\n4", "3", "0\n2\n2"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int R, C; cin >> R >> C;
        int a[MAX][MAX] = {};
        for (int i = 0; i < R; ++i)
            for (int j = 0; j < C; ++j) cin >> a[i][j];
        printEvenCountPerRow(a, R, C);
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		# De 3
		"CSLT_EXAM_003_Q02": {
			"input": "7\n-3\n0\n1\n2\n9\n17\n25\n",
			"expected_cases": ["false", "false", "false", "true", "false", "true", "false"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        cout << (isPrime(n) ? "true" : "false") << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_003_Q03": {
			"input": "6\n0\n7\n10\n5072\n99999\n100000\n",
			"expected_cases": ["0", "7", "1", "14", "45", "1"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        cout << digitSum(n) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_003_Q04": {
			"input": "4\n5\n1 2 3 1 2\n4\n4 3 2 1\n0\n3\n1 3 5\n",
			"expected_cases": ["3 0", "1 0", "0 -1", "3 0"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        int start = 999;
        int length = longestIncreasingRun(a, n, start);
        cout << length << ' ' << start << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_003_Q05": {
			"input": "3\n2 3\n1 2 3\n4 5 6\n1 4\n7 8 9 10\n3 1\n-1\n0\n5\n",
			"expected_cases": ["1 4\n2 5\n3 6", "7\n8\n9\n10", "-1 0 5"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int R, C; cin >> R >> C;
        int A[MAX][MAX] = {}, T[MAX][MAX] = {};
        for (int i = 0; i < R; ++i)
            for (int j = 0; j < C; ++j) cin >> A[i][j];
        transpose(A, T, R, C);
        for (int i = 0; i < C; ++i) {
            for (int j = 0; j < R; ++j)
                cout << T[i][j] << (j + 1 == R ? '\\n' : ' ');
        }
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		# De 4
		"CSLT_EXAM_004_Q01": {
			"input": "7\n-1\n0\n4.9\n5\n7\n8.5\n11\n",
			"expected_cases": ["Invalid", "Not pass", "Not pass", "Pass", "Good", "Excellent", "Invalid"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        double x; cin >> x;
        STUDENT_SNIPPET
        cout << "\\n@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_004_Q02": {
			"input": "6\n1\n2\n6\n12\n25\n36\n",
			"expected_cases": ["1", "2", "4", "6", "3", "9"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        cout << countDivisors(n) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_004_Q03": {
			"input": "3\n1 2 3\n0.5 1.25 4\n2 3 5\n",
			"expected_cases": ["3.141593 6.000000", "0.785398 5.000000", "12.566371 15.000000"],
			"harness": """
int main() {
    int T; cin >> T;
    cout << fixed << setprecision(6);
    while (T--) {
        double r, w, h; cin >> r >> w >> h;
        cout << area(r) << ' ' << area(w, h) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_004_Q04": {
			"input": "4\n7\n0 1 0 2 0 3 4\n5\n0 0 0 0 0\n4\n1 2 3 4\n6\n0 -1 0 -2 3 0\n",
			"expected_cases": ["1 2 3 4 0 0 0", "0 0 0 0 0", "1 2 3 4", "-1 -2 3 0 0 0"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        moveZerosToEnd(a, n);
        for (int i = 0; i < n; ++i) cout << a[i] << (i + 1 == n ? '\\n' : ' ');
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_004_Q05": {
			"input": "4\n3 3\n1 2 3\n4 5 6\n7 8 9\n1 3\n2 4 6\n3 1\n-1\n2\n3\n2 2\n1 2\n3 4\n",
			"expected_cases": ["40", "12", "4", "10"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int R, C; cin >> R >> C;
        int a[MAX][MAX] = {};
        for (int i = 0; i < R; ++i)
            for (int j = 0; j < C; ++j) cin >> a[i][j];
        cout << borderSum(a, R, C) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		# De 5
		"CSLT_EXAM_005_Q01": {
			"input": "5\n0\n7\n2048\n1200\n1001\n",
			"expected_cases": ["0", "7", "8402", "21", "1001"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        cout << reverseDigits(n) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_005_Q02": {
			"input": "6\n0\n1\n2\n5\n10\n12\n",
			"expected_cases": ["1", "1", "2", "120", "3628800", "479001600"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        cout << factorial(n) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_005_Q03": {
			"input": "4\n5\n3 -1 9 0 4\n1\n-7\n4\n5 5 5 5\n3\n10 2 -3\n",
			"expected_cases": ["-1 9", "-7 -7", "5 5", "-3 10"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n; cin >> n;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        int mn = 0, mx = 0;
        findMinMax(a, n, mn, mx);
        cout << mn << ' ' << mx << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_005_Q04": {
			"input": "4\n3 5 1 9\n1 2 3\n3 5 3 9\n1 2 3\n3 3 1 8\n1 2 3\n3 5 5 7\n1 2 3\n",
			"expected_cases": ["1 4 1 9 2 3", "1 4 1 2 3 9", "0 3 1 2 3", "0 3 1 2 3"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int n, capacity, pos, x; cin >> n >> capacity >> pos >> x;
        int a[1000];
        for (int i = 0; i < n; ++i) cin >> a[i];
        bool ok = insertAt(a, n, capacity, pos, x);
        cout << (ok ? 1 : 0) << ' ' << n;
        for (int i = 0; i < n; ++i) cout << ' ' << a[i];
        cout << '\\n' << "@@CASE_END@@\\n" << flush;
    }
}
"""
		},
		"CSLT_EXAM_005_Q05": {
			"input": "4\n3 3\n0 1 2\n3 -1 4\n5 6 7\n2 3\n-1 0 3\n-2 4 5\n3 1\n0\n1\n2\n2 2\n-1 0\n-2 1\n",
			"expected_cases": ["2", "2", "1", "1"],
			"harness": """
int main() {
    int T; cin >> T;
    while (T--) {
        int R, C; cin >> R >> C;
        int a[MAX][MAX] = {};
        for (int i = 0; i < R; ++i)
            for (int j = 0; j < C; ++j) cin >> a[i][j];
        cout << countNonNegativeColumns(a, R, C) << '\\n';
        cout << "@@CASE_END@@\\n" << flush;
    }
}
"""
		}
	}

static func build_submission(question_id: String, student_code: String) -> Dictionary:
	return build_program(question_id, student_code)
