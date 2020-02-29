import cython
from typing import List, Tuple


IntList = List[int]
DigitList = IntList
Cell = Tuple[int, int]


ODD: DigitList = [1, 3, 5, 7, 9]
EVEN: DigitList = [2, 4, 6, 8]

class Sudoku:
    def __init__(self):
        self.pos: List[List[DigitList]] = \
                    [[EVEN, EVEN, EVEN, EVEN, ODD, ODD, ODD, ODD, ODD],
                    [ODD, ODD, ODD, EVEN, ODD, ODD, EVEN, EVEN, EVEN],
                    [EVEN, ODD, ODD, EVEN, EVEN, ODD, ODD, ODD, EVEN],
                    [ODD, ODD, EVEN, ODD, EVEN, EVEN, ODD, ODD, EVEN],
                    [ODD, EVEN, ODD, ODD, EVEN, EVEN, ODD, EVEN, ODD],
                    [EVEN, EVEN, ODD, ODD, ODD, ODD, EVEN, EVEN, ODD],
                    [ODD, EVEN, EVEN, ODD, ODD, EVEN, ODD, EVEN, ODD],
                    [EVEN, ODD, EVEN, ODD, ODD, ODD, EVEN, ODD, EVEN],
                    [ODD, ODD, ODD, EVEN, EVEN, EVEN, EVEN, ODD, ODD]]
        self.fixed: List[DigitList] = [[0] * 9 for _ in range(9)]
        self.rec_cnt: cython.int = 0

    def check_constraints(self):
        possible: bool = True
        possible &= self.check_little_killer((1,2), 11)
        possible &= self.check_little_killer((1,3), 21)
        possible &= self.check_little_killer((1,4), 17)
        possible &= self.check_little_killer((2,9), 7)
        possible &= self.check_little_killer((3,9), 9)
        possible &= self.check_little_killer((4,9), 22)
        possible &= self.check_little_killer((9,6), 9)
        possible &= self.check_little_killer((9,7), 22)
        possible &= self.check_little_killer((9,8), 9)
        possible &= self.check_little_killer((6,1), 18)
        possible &= self.check_little_killer((7,1), 13)
        possible &= self.check_little_killer((8,1), 15)

        cdef int row_idx, col_idx, row, col
        for row_idx in range(9):
            possible &= self.check_region([self.fixed[row_idx][i] for i in range(9)])
        for col_idx in range(9):
            possible &= self.check_region([self.fixed[i][col_idx] for i in range(9)])
        for row_idx in range(3):
            for col_idx in range(3):
                digits: DigitList = []
                for row in range(3*row_idx, 3*row_idx+3):
                    for col in range(3*col_idx, 3*col_idx+3):
                        digits.append(self.fixed[row][col])
                possible &= self.check_region(digits)
        
        return possible

    def check_region(self, digits: DigitList) -> bool:
        cnts: IntList = [0] * 10
        cdef int digit
        for digit in digits:
            cnts[digit] += 1
        return max(cnts[1:]) <= 1

    def check_little_killer(self, start: Cell, goal: cython.int) -> bool:
        digits = [self.fixed[x-1][y-1] for (x, y) in self.little_killer(start)]
        if sum(digits) == goal and 0 not in digits:
            return True
        if sum(digits) < goal and 0 in digits:
            return True
        return False

    def little_killer(self, start):
        cur: Cell = start
        direction: Cell
        if start[0] == 1:
            direction = (1, -1)
        if start[0] == 9:
            direction = (-1, 1)
        if start[1] == 1:
            direction = (1, 1)
        if start[1] == 9:
            direction = (-1, -1)

        while min(cur) > 0 and max(cur) < 10:
            yield cur
            cur = (cur[0] + direction[0], cur[1] + direction[1])

    def __repr__(self):
        lines = []
        for row in self.fixed:
            line = [''.join('.123456789'[x] for x in chunk)
                    for chunk in chunks(row, 3)]
            lines.append('|'.join(line))
        rep =  '\n--- --- ---\n'.join(['\n'.join(chunk)
                                       for chunk in chunks(lines, 3)])
        return f"{self.rec_cnt}\n{rep}\n"

    def solve_rec(self, row: cython.int = 0, col: cython.int = 0):
        self.rec_cnt += 1
        if self.rec_cnt % 10_000 == 0:
            self.show_progress()
        cdef int value
        for value in self.pos[row][col]:
            self.fixed[row][col] = value
            if self.check_constraints():
                if row == col == 8:
                    print(self)
                    # exit()
                    continue
                self.solve_rec(row+(col+1)//9, (col+1)%9)

        self.fixed[row][col] = 0

    def show_progress(self):
        progress = 0.
        full_progress = 1.
        for idx in range(9):
            digit = self.fixed[0][idx]
            if digit == 0:
                break
            max_possibles = len(self.pos[0][idx])
            full_progress /= max_possibles
            progress += full_progress * self.pos[0][idx].index(digit)

        print(f"Progress: {progress:.2%}")


def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]
