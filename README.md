# Sudoku Solver

For [UKPA Hybrid Sudoku Contest](https://ukpuzzles.org/contests.php?contestid=56) problem 6: Little Killer and Even.

I'm trying to find all solutions via brute force + backtracking, and compare the speed using normal Python, Cython and C++.

Here are the timing results for different versions of the program. See the Git history for the different source codes.

| Description                                | Time            | Speedup  |
| ------------------------------------------ | --------------: | -------: |
| Python                                     | 878.19s         | 1.00x    |
| Cython                                     | 521.93s         | 1.68x    |
| Cython (more typing)                       | 417.01s         | 2.10x    |
| Cython (even more typing)                  | 373.33s         | 2.35x    |
| C++ (straightforward translation)          | 23.79s          | 36.91x   |
| Cython (fix all unnecessary conversions)   | 26.36s          | 33.32x   |
| C++ (exit early from constraints check)    | 17.54s          | 50.06x   |
| Cython (exit early from constraints check) | 18.74s          | 46.86x   |
| Cython (fewer progress messages)           | 14.85s          | 59.13x   |
| Cython (more efficient checking)           | 3.45s           | 254.54x  |
| Cython (mask for everything)               | 2.50s           | 351.27x  |
| Cython (cleaning + small killer opt)       | 2.11s           | 416.20x  |
| Cython (only test necessary killer)        | 0.09s           | 9757.66x |

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
