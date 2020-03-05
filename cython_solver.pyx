# cython: language_level=3
# distutils: language=c++
import cython
from libcpp.vector cimport vector
from libcpp.utility cimport pair

ctypedef pair[int, int] Cell
ctypedef pair[Cell, int] LittleKillerConstraint


cdef vector[int] ODD
cdef vector[int] EVEN
cdef int idx
for idx in range(1, 10, 2):
    ODD.push_back(idx)
for idx in range(2, 10, 2):
    EVEN.push_back(idx)


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
cdef class Sudoku:
    cdef vector[vector[vector[int]]] pos
    cdef vector[vector[int]] fixed
    cdef int rec_cnt
    cdef vector[LittleKillerConstraint] killer_contraints

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
                                  ((1, 3), 21),
                                  ((1, 4), 17),
                                  ((2, 9), 7),
                                  ((3, 9), 9),
                                  ((4, 9), 22),
                                  ((9, 6), 9),
                                  ((9, 7), 22),
                                  ((9, 8), 9),
                                  ((6, 1), 18),
                                  ((7, 1), 13),
                                  ((8, 1), 15)]

    cdef bint check_constraints(self):
        possible: bint = True
        cdef Cell start
        cdef int goal
        cdef LittleKillerConstraint contraint
        for contraint in self.killer_contraints:
            start, goal = contraint.first, contraint.second
            possible &= self.check_little_killer(start, goal)

        cdef int row_idx, col_idx, block_idx
        for row_idx in range(9):
            possible &= self.check_region(self.fixed[row_idx])
        for col_idx in range(9):
            possible &= self.check_region(self.get_col(col_idx))
        for block_idx in range(9):
            possible &= self.check_region(self.get_block(block_idx))

        return possible

    cdef vector[int] get_col(self, int col_idx):
        cdef vector[int] digits
        digits.reserve(9)
        for row_idx in range(9):
            digits.push_back(self.fixed[row_idx][col_idx])
        return digits

    cdef vector[int] get_block(self, int block_idx):
        cdef int row_idx = block_idx // 3, col_idx = block_idx % 3, row, col
        cdef vector[int] digits
        digits.reserve(9)
        for row in range(3):
            for col in range(3):
                digits.push_back(self.fixed[3*row_idx + row][3 * col_idx + col])
        return digits

    cdef bint check_region(self, digits: vector[cython.int]):
        cdef int[10] cnts
        cdef int i
        for i in range(10):
            cnts[i] = 0
        cdef int digit
        for digit in digits:
            cnts[digit] += 1
        cnts[0] = 0

        cdef int m = 0, c
        for c in cnts:
            m = max(m, c)
        return m <= 1

    cdef bint check_little_killer(self, Cell start, int goal):
        tmp = self.little_killer(start)
        cdef vector[int] digits
        digits.reserve(tmp.size())
        cdef Cell xy
        for xy in tmp:
            digits.push_back(self.fixed[xy.first-1][xy.second-1])

        cdef int s = 0, i
        for i in digits:
            s += i
        if s == goal and count(digits, 0) == 0:
            return True
        if s < goal and count(digits, 0) > 0:
            return True
        return False

    cdef vector[Cell] little_killer(self, Cell start):
        cdef Cell cur = start, direction
        if start.first == 1:
            direction = Cell(1, -1)
        if start.first == 9:
            direction = Cell(-1, 1)
        if start.second == 1:
            direction = Cell(1, 1)
        if start.second == 9:
            direction = Cell(-1, -1)

        cdef vector[Cell] cells
        while min(cur.first, cur.second) > 0 and max(cur.first, cur.second) < 10:
            cells.push_back(cur)
            cur = Cell(cur.first + direction.first, cur.second + direction.second)
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

    cdef solve_rec(self, int row, int col):
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


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
cdef int count(vector[int] v, int x):
    cdef int e, c = 0
    for e in v:
        if x == e:
            c += 1
    return c
