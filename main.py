from solver import Sudoku


if __name__ == "__main__":
    sudoku = Sudoku()
    sudoku.solve_rec()
    print(f"Total recursive iterations: {sudoku.rec_cnt}")
