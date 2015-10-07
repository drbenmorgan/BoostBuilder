cmake_minimum_required(VERSION 2.8.12)
project(BoostBuilderClient)

# - Can use standard setup variables that FindBoost knows
#set(Boost_USE_STATIC_LIBS ON)

# - Same find_package interface, enforcing use of BoostConfig
find_package(Boost 1.58 REQUIRED COMPONENTS filesystem system NO_MODULE)

# NB, if one wants to support *both* BoostConfig.cmake, but also allow
# clients who don't have it to build (accepting the issues with FindBoost)
# then do:
#
#  # NB: QUIET suppresses the big warning issued, and allows fallback
#  find_package(Boost 1.58 QUIET NO_MODULE COMPONENTS filesystem system)
#  if(NOT Boost_FOUND)
#    # Do warn about falling back to system, but can make message more
#    # explicit/informative
#    message(STATUS "No BoostConfig.cmake config file found, falling back to FindBoost...")
#    # Use REQUIRED flag to fail if not found
#    find_package(Boost 1.58 REQUIRED COMPONENTS filesystem system)
#  endif()

# - Build a test program
add_executable(BoostBuilderClient BoostBuilderClient.cpp)

# - Use/Link it to a boost library, BoostBuilder sets the same variables
#   to libs as FindBoost does, but these are imported targets so
#   always expand to the exact library used
target_include_directories(BoostBuilderClient PRIVATE ${Boost_INCLUDE_DIRS})
target_link_libraries(BoostBuilderClient
  PRIVATE ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY}
  )




