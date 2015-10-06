# - CMake build/bundle script for Boost Libraries
#   Automates build of Boost, allowing optional builds of library
#   components plus CMake/pkg-config support files
#
# In current form, install Boost libraries in "tagged" layout so that
# Release/Debug/Profile Single/Multithread variants can be installed
# alongside each other. Fairly easy to modify to allow separation of
# these.

#-----------------------------------------------------------------------
# Copyright (c) 2012-2013, Ben Morgan <bmorgan.warwick@gmail.com>
# Copyright (c) 2012-2013, University of Warwick
#
# Distributed under the OSI-approved BSD 3-Clause License (the "License");
# see accompanying file License.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#-----------------------------------------------------------------------

cmake_minimum_required(VERSION 3.2)
project(BoostBuilder)

#-----------------------------------------------------------------------
# CORE CONFIGURE/BUILD OPTIONS
#-----------------------------------------------------------------------
# - CMake utilities
include(BoostBuildUtility.cmake)
include(GNUInstallDirs)

# Basic Boost Parameters
set(Boost_VERSION 1.59.0)

# - List libraries to always build.
# We will construct the final list in the setup phase because bootstrap
# is pernickety about the --with/without-libraries being called more
# than once...
# The complete list of libraries provided by Boost can be found by
# running the bootstrap.sh script supplied with Boost as:
#   ./bootstrap.sh --with-libraries=all --show-libraries
set(Boost_INSTALLED_LIBRARIES
  date_time
  filesystem
  iostreams
  math
  program_options
  random
  serialization
  system
  test
  thread
  )
set(Boost_CONFIGURE_ARGS )
set(Boost_BUILD_ARGS )

#-----------------------------------------------------------------------
# VARIANTS
#-----------------------------------------------------------------------
# - Extra libraries - not complete, only most useful
set(Boost_OPTIONAL_LIBRARIES
  atomic
  chrono
  regex
  timer
  log
  )

foreach(_oplib ${Boost_OPTIONAL_LIBRARIES})
  option(boost.${_oplib} "Build Boost.${_oplib} Library" OFF)
  if(boost.${_oplib})
    list(APPEND Boost_INSTALLED_LIBRARIES ${_oplib})
  endif()
endforeach()

#-----------------------------------------------------------------------
# - Threading model
option(boost.singlethread "Build Boost single threaded library variants" OFF)
if(boost.singlethread)
  list(APPEND Boost_BUILD_ARGS "threading=multi,single")
else()
  list(APPEND Boost_BUILD_ARGS "threading=multi")
endif()

#-----------------------------------------------------------------------
# - Static libraries
option(boost.staticlibs "Build Boost static library variants" OFF)
if(boost.staticlibs)
  list(APPEND Boost_BUILD_ARGS "link=shared,static")
else()
  list(APPEND Boost_BUILD_ARGS "link=shared")
endif()

#-----------------------------------------------------------------------
# - Release/Debug/Profile libraries
# NB... To support profile libs, need to patch Boost's
# tools/build/src/tools/common.jam
# to add an entry in `local rule runtime-tag` to add a letter
# tag for profiling. Not yet clear if this rule can be overidden
# without patching
set(__boost.buildmodes "variant=release")

option(boost.debuglibs "Build Boost debug library variants" OFF)
if(boost.debuglibs)
  set(__boost.buildmodes "${__boost.buildmodes},debug")
endif()

#option(boost.profilelibs "Build boost profile library variants" OFF)
#if(boost.profilelibs)
#  set(__boost.buildmodes "${__boost.buildmodes},profile")
#endif()

list(APPEND Boost_BUILD_ARGS "${__boost.buildmodes}")

#-----------------------------------------------------------------------
# - Prebuild setup
# Determine the toolset in use by CMake and create needed configure/build
# arguments and custom user-config.jam file as needed
include(${PROJECT_SOURCE_DIR}/BoostToolsetId.cmake)
Boost_Get_ToolsetId(_boost_toolset)

# Need to find out how to add flags on a per variant mode
# ... e.g. "gdwarf" etc as per
#https://cdcvs.fnal.gov/redmine/projects/build-framework/repository/boost-ssi-build/revisions/master/entry/build_boost.sh

# For GCC/Clang (could also add logic for 1y/14)
set(Boost_CXX_STANDARD_FLAGS "-std=c++11")

# For Apple, though Mavericks onwards should defaualt to libc++
if(CMAKE_COMPILER_ID STREQUAL "AppleClang")
  set(Boost_CXX_STANDARD_FLAGS "${Boost_CXX_STANDARD_FLAGS} -stdlib=libc++")
endif()

if(_boost_toolset)
  list(APPEND Boost_CONFIGURE_ARGS "toolset=${_boost_toolset}")
  list(APPEND Boost_BUILD_ARGS     "toolset=${_boost_toolset}")

  set(Boost_USER_CONFIG_JAMFILE "${PROJECT_BINARY_DIR}/user-config.jam")
  file(WRITE "${Boost_USER_CONFIG_JAMFILE}" "using ${_boost_toolset} : : ${CMAKE_CXX_COMPILER} : <cxxflags>\"${Boost_CXX_STANDARD_FLAGS}\" <linkflags>\"${Boost_CXX_STANDARD_FLAGS}\" ;")
  set(Boost_BUILD_USER_CONFIG_ARGS "--user-config=${PROJECT_BINARY_DIR}/user-config.jam")
  list(APPEND Boost_BUILD_ARGS     "${Boost_BUILD_USER_CONFIG_ARGS}")
endif()

# Construct the final library list to install
join_list(Boost_INSTALLED_LIBRARIES "," Boost_WITHLIBRARY_LIST)
list(APPEND Boost_CONFIGURE_ARGS --with-libraries=${Boost_WITHLIBRARY_LIST})

# Parallelize build if possible
include(ProcessorCount)
ProcessorCount(NJOBS)
if(NJOBS EQUAL 0)
  set(NJOBS 1)
endif()

#-----------------------------------------------------------------------
# Build Boost
#
include(ExternalProject)
ExternalProject_Add(boost
  URL                 "https://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.bz2"
  URL_HASH            SHA256=727a932322d94287b62abb1bd2d41723eec4356a7728909e38adb65ca25241ca

  # If sourceforge downloads barf, copy by hand and stick it next to this
  #URL                 ${PROJECT_SOURCE_DIR}/boost_1_59_0.tar.bz2

  BUILD_IN_SOURCE     1
  CONFIGURE_COMMAND   <SOURCE_DIR>/bootstrap.sh
                      --prefix=${CMAKE_INSTALL_PREFIX}
                      # These can be adjusted
                      --libdir=${CMAKE_INSTALL_FULL_LIBDIR}
                      --includedir=${CMAKE_INSTALL_FULL_INCDIR}
                      ${Boost_CONFIGURE_ARGS}
  # All in one build/install step is slightly faster
  BUILD_COMMAND       ""
  INSTALL_COMMAND     ./b2 -d2 -q -j${NJOBS} install
                      --layout=tagged
                      --debug-configuration
                      ${Boost_BUILD_ARGS}
  STEP_TARGETS        download update configure install
  )

#-----------------------------------------------------------------------
# Custom step to build and install the bcp program
# We need to use a custom set of layout and toolset arguments to
# prevent "duplicate target" errors.
#
ExternalProject_Add_Step(boost install_bcp
  COMMAND           ./b2 -d2 -q -j${NJOBS}
                    ${Boost_BUILD_USER_CONFIG_ARGS}
                    ./tools/bcp
                    COMMAND           ${CMAKE_COMMAND} -E copy ./dist/bin/bcp ${CMAKE_INSTALL_FULL_BINDIR}/bcp
  DEPENDEES         install
  WORKING_DIRECTORY <BINARY_DIR>
  )

#-----------------------------------------------------------------------
# Create and install CMake support files.
# This uses a CMake script run at install time to do the heavy
# lifting of discovery of installed Boost libraries and setting
# up appropriate import targets for them.
#
set(Boost_INSTALL_CMAKEDIR "${CMAKE_INSTALL_FULL_LIBDIR}/cmake/Boost-${Boost_VERSION}")

configure_file(
  ${PROJECT_SOURCE_DIR}/BoostWriteCMakeImportFiles.cmake.in
  ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
  @ONLY
  )

configure_file(
  ${PROJECT_SOURCE_DIR}/BoostConfigVersion.cmake.in
  ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
  @ONLY
  )

configure_file(
  ${PROJECT_SOURCE_DIR}/BoostConfig.cmake.in
  ${PROJECT_BINARY_DIR}/BoostConfig.cmake
  @ONLY
  )

# Step for installation of all the above, as required
ExternalProject_Add_Step(boost install_cmake
  COMMAND ${CMAKE_COMMAND} -E make_directory ${Boost_INSTALL_CMAKEDIR}
  COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_BINARY_DIR}/BoostConfig.cmake ${Boost_INSTALL_CMAKEDIR}
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake ${Boost_INSTALL_CMAKEDIR}
  DEPENDEES install
  DEPENDS   ${PROJECT_SOURCE_DIR}/BoostLibraryDepends.cmake.in
            ${PROJECT_BINARY_DIR}/BoostWriteCMakeImportFiles.cmake
            ${PROJECT_BINARY_DIR}/BoostConfigVersion.cmake
            ${PROJECT_BINARY_DIR}/BoostConfig.cmake
  )


