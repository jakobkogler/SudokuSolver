# cython: language_level=3
# distutils: language=c++
import cython
from libcpp.vector cimport vector
from libcpp.utility cimport pair

ctypedef pair[int, int] Cell
ctypedef pair[vector[int], int] LittleKillerConstraint


cdef int ODD = 0b1010101010
cdef int EVEN = 0b101010100


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
cdef class Sudoku:
    cdef vector[int] pos
    cdef vector[int] fixed
    cdef int rec_cnt
    cdef vector[LittleKillerConstraint] killer_contraints
    cdef int[9] row_masks
    cdef int[9] col_masks
    cdef int[9] block_masks

    def __init__(self, odd_even_description, little_killer_constraints):
        self.pos = [(EVEN, ODD)[int(c)] for c in odd_even_description if c in "01"]
        self.fixed = [0] * 81
        self.rec_cnt = 0

        for start, goal in little_killer_constraints:
            self.add_little_killer_constraint(start, goal)

    def add_little_killer_constraint(self, Cell start, int goal):
        cells = self.get_diag(start)
        self.killer_contraints.push_back(LittleKillerConstraint(cells, goal))

    @staticmethod
    cdef inline int cell_idx(int row_idx, int col_idx):
        return row_idx * 9 + col_idx

    cdef bint check_additional_constraints(self, int row_idx, int col_idx):
        cdef vector[int] cells
        cdef int goal
        cdef LittleKillerConstraint contraint
        for contraint in self.killer_contraints:
            cells, goal = contraint.first, contraint.second
            if not self.check_little_killer(cells, goal):
                return False
        return True

    cdef vector[int] get_row(self, int row_idx):
        cdef vector[int] digits
        digits.reserve(9)
        for col_idx in range(9):
            digits.push_back(self.fixed[Sudoku.cell_idx(row_idx, col_idx)])
        return digits

    cdef vector[int] get_col(self, int col_idx):
        cdef vector[int] digits
        digits.reserve(9)
        for row_idx in range(9):
            digits.push_back(self.fixed[Sudoku.cell_idx(row_idx, col_idx)])
        return digits

    cdef vector[int] get_block(self, int block_idx):
        cdef int row_idx = block_idx // 3, col_idx = block_idx % 3, row, col
        cdef vector[int] digits
        digits.reserve(9)
        for row in range(3):
            for col in range(3):
                digits.push_back(self.fixed[Sudoku.cell_idx(3*row_idx + row, 3 * col_idx + col)])
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

    cdef bint check_little_killer(self, vector[int] cells, int goal):
        cdef vector[int] digits
        digits.reserve(cells.size())
        cdef int cell_idx
        for cell_idx in cells:
            digits.push_back(self.fixed[cell_idx])

        cdef int s = 0, i
        for i in digits:
            s += i
        if s == goal and count(digits, 0) == 0:
            return True
        if s < goal and count(digits, 0) > 0:
            return True
        return False

    def get_diag(self, Cell start):
        cdef Cell cur = start, direction
        if start.first == 1:
            direction = Cell(1, -1)
        if start.first == 9:
            direction = Cell(-1, 1)
        if start.second == 1:
            direction = Cell(1, 1)
        if start.second == 9:
            direction = Cell(-1, -1)

        cells = []
        while min(cur) > 0 and max(cur) < 10:
            cells.append(Sudoku.cell_idx(cur.first - 1, cur.second - 1))
            cur = Cell(cur.first + direction.first, cur.second + direction.second)
        return cells

    def __repr__(self):
        lines = []
        for row in chunks(self.fixed, 9):
            line = [''.join('.123456789'[x] for x in chunk)
                    for chunk in chunks(row, 3)]
            lines.append('|'.join(line))
        rep =  '\n--- --- ---\n'.join(['\n'.join(chunk)
                                       for chunk in chunks(lines, 3)])
        return f"{self.rec_cnt}\n{rep}\n"

    cpdef solve_rec(self, int row = 0, int col = 0):
        self.rec_cnt += 1
        if row == 0 and col == 3:
            self.show_progress()
        cdef int block = (row // 3) * 3 + (col // 3)
        cdef int row_mask = self.row_masks[row]
        cdef int col_mask = self.col_masks[col]
        cdef int block_mask = self.block_masks[block]
        cdef int possible_mask = self.pos[Sudoku.cell_idx(row, col)] & ~row_mask & ~col_mask & ~block_mask
        cdef int value
        for value in range(1, 10):
            if (1 << value) & possible_mask:
                self.fixed[Sudoku.cell_idx(row, col)] = value
                if self.check_additional_constraints(row, col):
                    if row == col == 8:
                        print(self)
                        continue
                    self.row_masks[row] = row_mask | (1 << value)
                    self.col_masks[col] = col_mask | (1 << value)
                    self.block_masks[block] = block_mask | (1 << value)
                    self.solve_rec(row+(col+1)//9, (col+1)%9)

        self.fixed[Sudoku.cell_idx(row, col)] = 0
        self.row_masks[row] = row_mask
        self.col_masks[col] = col_mask
        self.block_masks[block] = block_mask

    cdef show_progress(self):
        progress = 0.
        full_progress = 1.
        for idx in range(9):
            digit = self.fixed[idx]
            if digit == 0:
                break
            mask = self.pos[idx]
            max_possibles = sum('1' == c for c in bin(mask))
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
