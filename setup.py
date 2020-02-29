from distutils.core import setup
from Cython.Build import cythonize

setup(name='cython_solver',
      ext_modules=cythonize("cython_solver.pyx"))
