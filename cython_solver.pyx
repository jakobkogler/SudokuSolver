# distutils: language=c++
import cython
from libcpp.vector cimport vector
from libcpp.pair cimport pair
from typing import List, Tuple


IntList = List[int]
DigitList = IntList
Cell = Tuple[int, int]


cdef vector[int] ODD
cdef vector[int] EVEN
cdef int idx
for idx in range(1, 10, 2):
    ODD.push_back(idx)
for idx in range(2, 10, 2):
    EVEN.push_back(idx)


cdef class Sudoku:
    cdef vector[vector[vector[int]]] pos
    cdef vector[vector[int]] fixed
    cdef int rec_cnt
    cdef vector[pair[pair[cython.int, cython.int], cython.int]] killer_contraints

    def __init__(self):
        self.pos = [[EVEN, EVEN, EVEN, EVEN, ODD, ODD, ODD, ODD, ODD],
                    [ODD, ODD, ODD, EVEN, ODD, ODD, EVEN, EVEN, EVEN],
                    [EVEN, ODD, ODD, EVEN, EVEN, ODD, ODD, ODD, EVEN],
                    [ODD, ODD, EVEN, ODD, EVEN, EVEN, ODD, ODD, EVEN],
                    [ODD, EVEN, ODD, ODD, EVEN, EVEN, ODD, EVEN, ODD],
                    [EVEN, EVEN, ODD, ODD, ODD, ODD, EVEN, EVEN, ODD],
                    [ODD, EVEN, EVEN, ODD, ODD, EVEN, ODD, EVEN, ODD],
                    [EVEN, ODD, EVEN, ODD, ODD, ODD, EVEN, ODD, EVEN],
                    [ODD, ODD, ODD, EVEN, EVEN, EVEN, EVEN, ODD, ODD]]
        self.fixed = [[0] * 9 for _ in range(9)]
        self.rec_cnt = 0
        self.killer_contraints = [((1, 2), 11),
                                  ((1,3), 21),
                                  ((1,4), 17),
                                  ((2,9), 7),
                                  ((3,9), 9),
                                  ((4,9), 22),
                                  ((9,6), 9),
                                  ((9,7), 22),
                                  ((9,8), 9),
                                  ((6,1), 18),
                                  ((7,1), 13),
                                  ((8,1), 15)]

    cdef check_constraints(self):
        possible: bool = True
        cdef pair[cython.int, cython.int] start
        cdef cython.int goal
        for start, goal in self.killer_contraints:
            possible &= self.check_little_killer(start, goal)

        cdef int row_idx, col_idx, row, col
        for row_idx in range(9):
            possible &= self.check_region([self.fixed[row_idx][i] for i in range(9)])
        for col_idx in range(9):
            possible &= self.check_region([self.fixed[i][col_idx] for i in range(9)])
        cdef vector[int] block_digits
        for row_idx in range(3):
            for col_idx in range(3):
                block_digits.clear()
                for row in range(3*row_idx, 3*row_idx+3):
                    for col in range(3*col_idx, 3*col_idx+3):
                        block_digits.push_back(self.fixed[row][col])
                possible &= self.check_region(block_digits)
        
        return possible

    cdef bint check_region(self, digits: vector[cython.int]):
        cnts: vector[cython.int] = [0] * 10
        cdef int digit
        for digit in digits:
            cnts[digit] += 1
        cnts[0] = 0
        return max(cnts) <= 1

    cdef bint check_little_killer(self, start: pair[cython.int, cython.int], goal: cython.int):
        tmp = self.little_killer(start)
        digits = [self.fixed[x-1][y-1] for (x, y) in tmp]
        if sum(digits) == goal and 0 not in digits:
            return True
        if sum(digits) < goal and 0 in digits:
            return True
        return False

    cdef vector[pair[cython.int, cython.int]] little_killer(self, start: pair[cython.int, cython.int]):
        cur: pair[cython.int, cython.int] = start
        cdef pair[cython.int, cython.int] direction
        if start.first == 1:
            direction = pair[cython.int, cython.int](1, -1)
        if start.first == 9:
            direction = pair[cython.int, cython.int](-1, 1)
        if start.second == 1:
            direction = pair[cython.int, cython.int](1, 1)
        if start.second == 9:
            direction = pair[cython.int, cython.int](-1, -1)

        cdef vector[pair[cython.int, cython.int]] cells
        while min(cur) > 0 and max(cur) < 10:
            cells.push_back(cur)
            cur = pair[cython.int, cython.int](cur.first + direction.first, cur.second + direction.second)
        return cells

    def __repr__(self):
        lines = []
        for row in self.fixed:
            line = [''.join('.123456789'[x] for x in chunk)
                    for chunk in chunks(row, 3)]
            lines.append('|'.join(line))
        rep =  '\n--- --- ---\n'.join(['\n'.join(chunk)
                                       for chunk in chunks(lines, 3)])
        return f"{self.rec_cnt}\n{rep}\n"

    def solve(self):
        self.solve_rec(0, 0)

    cdef solve_rec(self, row: cython.int = 0, col: cython.int = 0):
        self.rec_cnt += 1
        if self.rec_cnt % 10_000 == 0:
            self.show_progress()
        cdef int value
        for value in self.pos[row][col]:
            self.fixed[row][col] = value
            if self.check_constraints():
                if row == col == 8:
                    print(self)
                    continue
                self.solve_rec(row+(col+1)//9, (col+1)%9)

        self.fixed[row][col] = 0

    cdef show_progress(self):
        progress = 0.
        full_progress = 1.
        for idx in range(9):
            digit = self.fixed[0][idx]
            if digit == 0:
                break
            max_possibles = len(self.pos[0][idx])
            full_progress /= max_possibles
            progress += full_progress * ((digit-1) // 2)

        print(f"Progress: {progress:.2%}")


def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]
