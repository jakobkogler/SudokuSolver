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
    cdef int[81] pos
    cdef int[81] fixed
    cdef vector[KillerConstraint] killer_contraints
    cdef int[9] row_masks
    cdef int[9] col_masks
    cdef int[9] block_masks
    cdef (vector[int])[81] killer_lookup

    def __init__(self, board):
        self.pos = [self.parse_board_char(c) for c in board if self.parse_board_char(c)]
        self.fixed = [0] * 81

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
        for cell in cells:
            self.killer_lookup[cell].push_back(self.killer_contraints.size() - 1)

    @staticmethod
    cdef inline int cell_idx(int row_idx, int col_idx):
        return row_idx * 9 + col_idx

    cdef bint check_additional_constraints(self, int row_idx, int col_idx):
        cdef vector[int] cells
        cdef int goal, idx
        cdef KillerConstraint constraint
        for idx in self.killer_lookup[Sudoku.cell_idx(row_idx, col_idx)]:
            constraint = self.killer_contraints[idx]
            cells, goal = constraint.first, constraint.second
            if not self.check_killer_constraint(cells, goal):
                return False
        return True

    cdef bint check_killer_constraint(self, vector[int] cells, int goal):
        cdef int minsum = 0, maxsum = 0
        cdef int cell_idx, digit
        for cell_idx in cells:
            digit = self.fixed[cell_idx]
            if digit:
                minsum += digit
                maxsum += digit
            else:
                minsum += 1
                maxsum += 9
        return minsum <= goal and maxsum >= goal

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
        return rep

    cpdef solve_rec(self, int row = 0, int col = 0):
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


def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]
