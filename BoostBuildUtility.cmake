# - Useful CMake utility functions and macros
#
# CMake Utilities and Wrappers
# ---------------------------
# macro include_once(<module>)
#       Include a CMake module iff it has not already been included
#
# macro set_ifnot(<var> <value>)
#       If variable var is not set, set its value to that provided
#
# function enum_option(<option>
#                      VALUES <value1> ... <valueN>
#                      TYPE   <valuetype>
#                      DOC    <docstring>
#                      [DEFAULT <elem>]
#                      [CASE_INSENSITIVE])
#          Declare a cache variable <option> that can only take values
#          listed in VALUES. TYPE may be FILEPATH, PATH or STRING.
#          <docstring> should describe that option, and will appear in
#          the interactive CMake interfaces. If DEFAULT is provided,
#          <elem> will be taken as the zero-indexed element in VALUES
#          to which the value of <option> should default to if not
#          provided. Otherwise, the default is taken as the first
#          entry in VALUES. If CASE_INSENSITIVE is present, then
#          checks of the value of <option> against the allowed values
#          will ignore the case when performing string comparison.
#
# List Manipulation
# -----------------
# function count_matching(<list> <regex> <output variable>)
#          Set output to number of elements in list matching regex
#
# function join_list(<list> <separator> <output>)
#          Join elements of list using separator and set output to result
#
# Numerical and Math
# ------------------
# function float_as_fraction(<floatstring> <output variable>)
#          Convert a floating point number, input as a string, into
#          a fraction and write it to output. For example,
#
#            float_as_fraction("1.2" VAR)
#
#          will set VAR equal to 12/10
#

#-----------------------------------------------------------------------
# Copyright (c) 2012-2015, Ben Morgan <bmorgan.warwick@gmail.com>
# Copyright (c) 2012-2015, University of Warwick
#
# Distributed under the OSI-approved BSD 3-Clause License (the "License");
# see accompanying file License.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# CORE CMAKE DEPENDENCIES
#-----------------------------------------------------------------------
include(CMakeParseArguments)

#-----------------------------------------------------------------------
# CMAKE UTILITIES AND WRAPPERS
#-----------------------------------------------------------------------
# macro include_once(<module>)
#       Include a CMake module iff it has not already been included
#
macro(include_once _module)
  if(NOT ${_module}_IS_INCLUDED)
    include(${_module})
    set(${_module}_IS_INCLUDED 1)
  endif()
endmacro()

#-----------------------------------------------------------------------
# macro set_ifnot(<var> <value>)
#       If variable var is not set, set its value to that provided
#
macro(set_ifnot _var _value)
  if(NOT ${_var})
    set(${_var} ${_value})
  endif()
endmacro()

#-----------------------------------------------------------------------
# function enum_option(<option>
#                      VALUES <value1> ... <valueN>
#                      TYPE   <valuetype>
#                      DOC    <docstring>
#                      [DEFAULT <elem>]
#                      [CASE_INSENSITIVE])
#          Declare a cache variable <option> that can only take values
#          listed in VALUES.
#
function(enum_option _var)
  set(options CASE_INSENSITIVE)
  set(oneValueArgs DOC TYPE DEFAULT)
  set(multiValueArgs VALUES)
  cmake_parse_arguments(_ENUMOP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # - Validation as needed arguments
  if(NOT _ENUMOP_VALUES)
    message(FATAL_ERROR "enum_option must be called with non-empty VALUES\n(Called for enum_option '${_var}')")
  endif()

  # - Set argument defaults as needed
  if(_ENUMOP_CASE_INSENSITIVE)
    set(_ci_values )
    foreach(_elem ${_ENUMOP_VALUES})
      string(TOLOWER "${_elem}" _ci_elem)
      list(APPEND _ci_values "${_ci_elem}")
    endforeach()
    set(_ENUMOP_VALUES ${_ci_values})
  endif()

  set_ifnot(_ENUMOP_TYPE STRING)
  set_ifnot(_ENUMOP_DEFAULT 0)
  list(GET _ENUMOP_VALUES ${_ENUMOP_DEFAULT} _default)

  if(NOT DEFINED ${_var})
    set(${_var} ${_default} CACHE ${_ENUMOP_TYPE} "${_ENUMOP_DOC} (${_ENUMOP_VALUES})")
  else()
    set(_var_tmp ${${_var}})
    if(_ENUMOP_CASE_INSENSITIVE)
      string(TOLOWER ${_var_tmp} _var_tmp)
    endif()

    list(FIND _ENUMOP_VALUES ${_var_tmp} _elem)
    if(_elem LESS 0)
      message(FATAL_ERROR "Value '${${_var}}' for variable ${_var} is not allowed\nIt must be selected from the set: ${_ENUMOP_VALUES} (DEFAULT: ${_default})\n")
    else()
      # - convert to lowercase
      if(_ENUMOP_CASE_INSENSITIVE)
        set(${_var} ${_var_tmp} CACHE ${_ENUMOP_TYPE} "${_ENUMOP_DOC} (${_ENUMOP_VALUES})" FORCE)
      endif()
    endif()
  endif()
endfunction()

#-----------------------------------------------------------------------
# logging?

#-----------------------------------------------------------------------
# LIST MANIPULATION
#-----------------------------------------------------------------------
# function count_matching(<list> <regex> <output variable>)
#          Set output to number of elements in list matching regex
#
function(count_matching _list _regex _output)
  set(_counted 0)
  foreach(_elem ${${_list}})
    if(_elem MATCHES "${_regex}")
      math(EXPR _counted "${_counted} + 1")
    endif()
  endforeach()
  set(${_output} ${_counted} PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------------------
# function join_list(<list> <separator> <output variable>)
#          Join elements of list using separator and set output to result
#
function(join_list _list _separator _var)
  set(tmpstring)
  if(DEFINED "${_list}")
    set(tmplist "${${_list}}")
  else()
    set(tmplist "${_list}")
  endif()
  string(REPLACE ";" "${_separator}" tmpstring "${tmplist}")
  set(${_var} "${tmpstring}" PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------------------
# NUMERICAL/MATH PROCESSING
#----------------------------------------------------------------------
# function float_as_fraction(<floatstring> <output variable>)
#          Convert a floating point number, input as a string, into
#          a fraction and write it to output. For example,
#
#            float_as_fraction("1.2" VAR)
#
#          will set VAR equal to 12/10
#
#          Limitation: WILL NOT WORK IF NUMERATOR GOES ABOVE MAX_INT!!
#
function(float_as_fraction _string _fraction)
  # Check format
  string(REGEX MATCHALL "[0-9]|\\." _digits ${_string})
  count_matching(_digits "\\." _dpcount)
  if(_dpcount EQUAL 0)
    set(${_fraction} ${_string} PARENT_SCOPE)
    return()
  elseif(_dpcount GREATER 1)
    message(FATAL_ERROR "Incorrectly formatted floating point number")
  endif()

  # Find number of decimal places, and hence denominator
  list(LENGTH _digits _digitlength)
  list(FIND _digits "." _decimalpoint)
  math(EXPR _dplaces "${_digitlength} - (${_decimalpoint} + 1)")

  # zero decimal places
  if(_dplaces EQUAL 0)
    list(REVERSE _digits)
    list(REMOVE_AT _digits 0)
    list(REVERSE _digits)
    string(REPLACE ";" "" _frac "${_digits}")
    set(${_fraction} ${_frac} PARENT_SCOPE)
  else()
    set(_denominator 1)
    foreach(_i RANGE 1 ${_dplaces})
      set(_denominator "${_denominator}0")
    endforeach()

    list(REMOVE_ITEM _digits ".")
    string(REPLACE ";" "" _numerator "${_digits}")
    set(${_fraction} "${_numerator}/${_denominator}" PARENT_SCOPE)
  endif()
endfunction()

