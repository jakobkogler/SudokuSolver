# cython: language_level=3
# distutils: language=c++
import cython
from libcpp.vector cimport vector
from libcpp.utility cimport pair

ctypedef pair[int, int] Cell
ctypedef pair[vector[int], int] KillerConstraint


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
cdef class Sudoku:
    cdef vector[int] pos
    cdef vector[int] fixed
    cdef int rec_cnt
    cdef vector[KillerConstraint] killer_contraints
    cdef int[9] row_masks
    cdef int[9] col_masks
    cdef int[9] block_masks

    def __init__(self, board):
        self.pos = [self.parse_board_char(c) for c in board if self.parse_board_char(c)]
        self.fixed = [0] * 81
        self.rec_cnt = 0

    def parse_board_char(self, c):
        if c in "123456789":  # digit already fixed
            return 1 << int(c)
        if c in "0.":  # empty cell
            return (1 << 10) - 1
        if c == "O":  # ODD
            return 0b1010101010
        if c == "E":  # EVEN
            return 0b101010100
        return 0

    def add_little_killer_constraint(self, Cell start, int goal):
        cells = self.get_diag(start)
        self.killer_contraints.push_back(KillerConstraint(cells, goal))

    @staticmethod
    cdef inline int cell_idx(int row_idx, int col_idx):
        return row_idx * 9 + col_idx

    cdef bint check_additional_constraints(self, int row_idx, int col_idx):
        cdef vector[int] cells
        cdef int goal
        cdef KillerConstraint contraint
        for contraint in self.killer_contraints:
            cells, goal = contraint.first, contraint.second
            if not self.check_killer_constraint(cells, goal):
                return False
        return True

    cdef bint check_killer_constraint(self, vector[int] cells, int goal):
        cdef vector[int] digits
        digits.reserve(cells.size())
        cdef int cell_idx
        for cell_idx in cells:
            digits.push_back(self.fixed[cell_idx])

        cdef int s = int_sum(digits), zeros = count(digits, 0)
        return s + zeros <= goal and s + zeros * 9 >= goal

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
cdef inline int count(vector[int] v, int x):
    cdef int e, c = 0
    for e in v:
        if x == e:
            c += 1
    return c


@cython.wraparound(False)
@cython.boundscheck(False)
@cython.nonecheck(False)
cdef inline int int_sum(vector[int] v):
    cdef int s = 0, e
    for e in v:
        s += e
    return s
