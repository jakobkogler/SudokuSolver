# Sudoku Solver

For [UKPA Hybrid Sudoku Contest](https://ukpuzzles.org/contests.php?contestid=56) problem 6: Little Killer and Even.

I'm trying to find all solutions via brute force + backtracking, and compare the speed using normal Python and Cython.

| Description                              | Time            | Speedup |
| ---------------------------------------- | --------------: | ------: |
| Python                                   | 878.19s         | 1.00x   |
| Cython                                   | 521.93s         | 1.68x   |
| Cython (more typing)                     | 417.01s         | 2.10x   |
| Cython (even more typing)                | 373.33s         | 2.35x   |
| C++                                      | 23.79s          | 36.91x  |
| Cython (fix all unnecessary conversions) | 26.36s          | 33.32x  |

The program can be exiting early if a constraint is validated.

| Description                              | Time            | Speedup |
| ---------------------------------------- | --------------: | ------: |
| C++                                      | 17.54s          | 50.06x  |
| Python                                   | 18.74s          | 46.86x  |
