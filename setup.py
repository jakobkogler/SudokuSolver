from distutils.core import setup
from Cython.Build import cythonize

setup(name='sudoku_solver',
      ext_modules=cythonize("sudoku_solver.pyx",
                            annotate=True))
