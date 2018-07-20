package main

import (
	"fmt"
	"strconv"
)

// 链接：https://www.nowcoder.com/questionTerminal/de1e1ff46cd641178a147166156c9d83
// 来源：牛客网
//
// 会下国际象棋的人都很清楚：皇后可以在横、竖、斜线上不限步数地吃掉其他棋子。如何将 8 个皇后放在棋盘上（有8×8个方格），使它们谁也不能被吃掉！这就是著名的八皇后问题。
// 对于某个满足要求的8皇后的摆放方法，定义一个皇后串a与之对应，即 a=b1b2...b8, 其中bi（1≤bi≤8）为相应摆法中第 i 行皇后所处的列数。已经知道8皇后问题一共有92组解（即92个不同的皇后串）。给出一个数n，要求输出第n个串。串的比较是这样的:皇后串x置于皇后串y之前，当且仅当将x视为整数时比y小。
//
// 输入描述:
// 输入包含多组数据。
//
// 每组数据包含一个正整数n（1≤n≤92）。
//
//
// 输出描述:
// 对应每一组输入，输出第n个皇后串。
//
// 示例1
// 输入
// 1
// 92
// 输出
// 15863724
// 84136275

func main() {
	n := 8
	count := 0
	sorted := 92
	var result = make([]int, n+1)
	place(1, n, sorted, &count, result)
	//place_queen(n, sorted,result, &count,)
	fmt.Println(count)
}

// 非递归解法
func place_queen(num, sorted int, result []int, count *int) {
	i := 1
	j := 1
	for i <= num {
		temp := false
		for j <= num {
			if isOk(i, j, result) {
				result[i] = j
				j = 1
				temp = true
				break
			} else {
				temp = false
				j++
			}
		}
		if !temp {
			if i == 1 {
				break
			} else {
				i--
				j = result[i] + 1
				result[i] = 0
				continue
			}
		} else if i == num {
			*count++
			if *count == sorted {
				print(result)
			}
			j = result[i] + 1
			result[i] = 0
			continue
		}
		i++
	}
}

// 递归解法
func place(k, n, sorted int, count *int, result []int) {
	if k > n {
		*count++
		if *count == sorted {
			print(result)
		}
		return
	}

	for i := 1; i <= n; i++ {
		if isOk(k, i, result) {
			result[k] = i
			place(k+1, n, sorted, count, result)
		}
	}

}

// 判断是否可放入函数
func isOk(row, col int, result []int) bool {
	for i := 1; i < row; i++ {
		if (col == result[i]) || (row-i == col-result[i]) || (row-i == result[i]-col) {
			return false
		}
	}
	return true
}

func print(result []int) {
	queenString := ""
	for k, v := range result {
		if k == 0 {
			continue
		}
		queenString += strconv.Itoa(v)
	}
	fmt.Println(queenString)
}
