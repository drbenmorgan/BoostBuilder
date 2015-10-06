BoostBuilder
============
Use CMake's [ExternalProject](https://cmake.org/cmake/help/v3.3/module/ExternalProject.html) module to download, configure, build and install
the Boost libraries. In addition, generate CMake support files for use
with the config mode of its [find_package](https://cmake.org/cmake/help/v3.3/command/find_package.html) command. This allows CMake based projects to
easily locate a Boost installed via BoostBuilder without relying on
CMake's builtin [FindBoost](https://cmake.org/cmake/help/v3.3/module/FindBoost.html) module. Due to Boost's complex system of tagging/versioning its libraries and some login in `FindBoost`, one can configure
with a mix of local and system Boost components. By using CMake's config
mode plus imported targets, these mixed configurations are prevented.

How to Build
============
Requirements:

1. CMake 3.2 or better
2. GCC 4.9 or better Clang 3.4 or better (inc Xcode 6/7). Intel compiler
   version 15 or better *should* also work.
3. Make implementation (ideally GNU Make)
4. Git (to clone this repo)
5. Working internet connection (to download the Boost sources)

To build/install, start by cloning this repo:

```
$ ls

$ git clone https://github.com/drbenmorgan/BoostBuilder.git BoostBuilder.git
...
$ ls
BoostBuilder.git
```

To keep the build isolated from the sources, create a parallel directory
in which to perform the build, and change into it:

```
$ mkdir Boost.Build
$ cd Boost.Build
```

Now run `cmake`, supplying an install prefix for Boost, and pointing cmake
to the BoostBuilder source directory:

```
$ cmake -DCMAKE_INSTALL_PREFIX=/where/you/want ../BoostBuilder.git
...
-- Configuring done
-- Generating done
-- Build files have been written to: /.../Boost.Build
$
```

Now run `make` to download, configure, build and install Boost and support
files:

```
$ make
Scanning dependencies of target boost
[ 10%] Creating directories for 'boost'
[ 20%] Performing download step (download, verify and extract) for 'boost'
-- downloading...
....
...updated 70 targets...
[100%] Completed 'boost'
[100%] Built target boost
$
```

By default, dynamic, optimized, multithreadsafe libraries are built,
using the C++11 standard:

```
├── bin
│   └── bcp
├── include
│   └── boost
└── lib
    ├── cmake
    │   └── Boost-1.59.0
    │       ├── BoostConfig.cmake
    │       ├── BoostConfigVersion.cmake
    │       ├── BoostLibraryDepends-shared-multithread-release.cmake
    │       └── BoostLibraryDepends-shared-multithread.cmake
    ├── libboost_chrono-mt.a
    ├── libboost_chrono-mt.dylib
    ├── libboost_date_time-mt.dylib
    ├── libboost_filesystem-mt.dylib
    ├── libboost_iostreams-mt.dylib
    ├── libboost_math_c99-mt.dylib
    ├── libboost_math_c99f-mt.dylib
    ├── libboost_math_c99l-mt.dylib
    ├── libboost_math_tr1-mt.dylib
    ├── libboost_math_tr1f-mt.dylib
    ├── libboost_math_tr1l-mt.dylib
    ├── libboost_prg_exec_monitor-mt.dylib
    ├── libboost_program_options-mt.dylib
    ├── libboost_random-mt.dylib
    ├── libboost_serialization-mt.dylib
    ├── libboost_system-mt.a
    ├── libboost_system-mt.dylib
    ├── libboost_test_exec_monitor-mt.a
    ├── libboost_thread-mt.dylib
    ├── libboost_timer-mt.a
    ├── libboost_timer-mt.dylib
    ├── libboost_unit_test_framework-mt.dylib
    └── libboost_wserialization-mt.dylib
```

Note that even when only dynamic libs are built, a couple of static libs
are also built. Only a subset of all Boost libraries are built.

Additional library variants can be built by setting
the CMake variables (via command line or CCMake):

- `boost.singlethread` : Set to `ON` (e.g. `-Dboost.singlethread=ON`) to
  build single thread mode libraries
- `boost.staticlibs` : Set to `ON` to enable the build of all libraries
  in static mode
- `boost.debuglibs` : Set to `ON` to build debug mode library variant

Boost's library tagged layout is used to uniquely name each variation
so that these can be installed alongside each other (NB this can
be changed). This means that if all of the above are set, there
will be eight variations of a library, i.e.:

- `libboost_<name>.(a|so)` = Optimized, Singlethreaded
- `libboost_<name>-mt.(a|so)` = Optimized, Multithreaded
- `libboost_<name>-d.(a|so)` = Debug, Singlethreaded
- `libboost_<name>-mt-d.(a|so)` = Debug, Multithreaded

At present, Boost's `profile` build mode is not supported as it does
not create a unique tag name for this mode without patching Boost.

With this full install, the set of CMake support files becomes:

```
├── bin
│   └── bcp
├── include
│   └── boost
└── lib
    ├── cmake
        └── Boost-1.59.0
            ├── BoostConfig.cmake
            ├── BoostConfigVersion.cmake
            ├── BoostLibraryDepends-shared-multithread-debug.cmake
            ├── BoostLibraryDepends-shared-multithread-release.cmake
            ├── BoostLibraryDepends-shared-multithread.cmake
            ├── BoostLibraryDepends-shared-singlethread-debug.cmake
            ├── BoostLibraryDepends-shared-singlethread-release.cmake
            ├── BoostLibraryDepends-shared-singlethread.cmake
            ├── BoostLibraryDepends-static-multithread-debug.cmake
            ├── BoostLibraryDepends-static-multithread-release.cmake
            ├── BoostLibraryDepends-static-multithread.cmake
            ├── BoostLibraryDepends-static-singlethread-debug.cmake
            ├── BoostLibraryDepends-static-singlethread-release.cmake
            └── BoostLibraryDepends-static-singlethread.cmake
```

As shown below, this allows selection between the different types.


Using BoostBuilder's CMake Support Files
========================================







