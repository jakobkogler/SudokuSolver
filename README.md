# Sudoku Solver

This was programmed for problem 6 (Little Killer and Even) of the [UKPA Hybrid Sudoku Contest](https://ukpuzzles.org/contests.php?contestid=56).
In order to handle the additional constraints given in this puzzle, this solver is can handle arbitrary many **Even clues** (forcing even numbers in certain cells), and arbitrary many **Little Killer** clues (forcing the sum of digits in certain diagonals).

I'm trying to find all solutions via brute force + backtracking, and compare the speed using normal Python, Cython and C++.

Here are the timing results for different versions of the program. See the Git history for the different source codes.

| Description                                | Time            | Speedup   |
| ------------------------------------------ | --------------: | --------: |
| Python                                     | 878.19s         | 1.00x     |
| Cython                                     | 521.93s         | 1.68x     |
| Cython (more typing)                       | 417.01s         | 2.10x     |
| Cython (even more typing)                  | 373.33s         | 2.35x     |
| C++ (straightforward translation)          | 23.79s          | 36.91x    |
| Cython (fix all unnecessary conversions)   | 26.36s          | 33.32x    |
| C++ (exit early from constraints check)    | 17.54s          | 50.06x    |
| Cython (exit early from constraints check) | 18.74s          | 46.86x    |
| Cython (fewer progress messages)           | 14.85s          | 59.13x    |
| Cython (more efficient checking)           | 3.45s           | 254.54x   |
| Cython (mask for everything)               | 2.50s           | 351.27x   |
| Cython (cleaning + small killer opt)       | 2.11s           | 416.20x   |
| Cython (only test necessary killer)        | 0.09s           | 9757.66x  |
| Cython (ctuple, void)                      | 0.08s           | 10977.38x |

## Instructions (for Python)

The program requires the Cython library for compiling. It's best to setup a new virtual environment for that purpose:

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install Cython
```

Then compile the Cython code:

```sh
python setup.py build_ext --inplace
```

Afterwards you can solve the Sudoku defined in `cython_main.py` with:

```sh
python cython_main.py
```

## Instructions (for C++)

Compile and run the code with:

```sh
g++ -std=c++17 -O3 solver.cpp -march=native -o solver.out
./solver.out
```

## Usage

```
>>> from cython_solver import Sudoku
>>> board = """.......5.
...            ..1..93..
...            9..7.1...
...            ..5.9.4.7
...            6...2...3
...            2.9.4.6..
...            ...5.2..1
...            ..48..2..
...            .1......."""
>>> sudoku.solve()
1 solutions found:

467|283|159
851|469|372
923|751|864
--- --- ---
135|698|427
648|127|593
279|345|618
--- --- ---
386|572|941
794|816|235
512|934|786
```

An additional example, using additional Even and Little Killer clues, is in the file `cython_main.py`.
