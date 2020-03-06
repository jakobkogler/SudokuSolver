from cython_solver import Sudoku


if __name__ == "__main__":
    board = """EEE|EOO|OOO
               OOO|EOO|EEE
               EOO|EEO|OOE
               --- --- ---
               OOE|OEE|OOE
               OEO|OEE|OEO
               EEO|OOO|EEO
               --- --- ---
               OEE|OOE|OEO
               EOE|OOO|EOE
               OOO|EEE|EOO"""
    constraints = [((1, 2), 11),
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

    sudoku = Sudoku(board)
    for start, goal in constraints:
        sudoku.add_little_killer_constraint(start, goal)
    sudoku.solve()
