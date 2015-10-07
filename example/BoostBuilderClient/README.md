BoostBuilderClient
==================
Micro demo of using building a program linking to Boost using the
BoostBuilder support files.

Requirements
============
- CMake 2.8.12 or above
- C++ compiler
- Boost installed via BoostBuilder

How to Build
============
Create a build directory:

```
$ mkdir build
$ cd build
$ ls ..
BoostBuilderClient.cpp README.md
CMakeLists.txt         build
$
```

To use BoostBuilder's CMake config files, the CMake variable 
`CMAKE_PREFIX_PATH` needs to contain the path under which you installed
BoostBuilder. For example, let's say you used `/my/boost/prefix`.
You can therefore now configure and build `BoostBuilderClient` by
doing:

```
$ cmake -DCMAKE_PREFIX_PATH=/my/boost/prefix ..
$ make
```

or via the environment (bash shell shown)

```
$ export CMAKE_PREFIX_PATH=/my/boost/prefix:$CMAKE_PREFIX_PATH
$ cmake ..
$ make
```

The CMakeLists.txt script supplied enforces use of the Config files,
but includes comments on how to modify to allow fallback to `FindBoost`.

