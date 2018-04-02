#.rst:
# FindTBB
# -------
# Find the TBB include directory and libraries
#
# The module supports the following components:
#
#    PREVIEW
#    MALLOC
#    MALLOC_PROXY
#    DEBUG
#
# Module Input Variables
# ^^^^^^^^^^^^^^^^^^^^^^
#
# Users or projects may set the following variables to configure the module
# behaviour:
#
# :variable:`NodeJS_RUNTIME_ROOT_DIR`
#   the root of the runtime installations.
#
# This module defines
# TBB_INCLUDE_DIR, where to find TBB.h
# TBB_LIBRARY, the library to link against to use TBB.
# TBB_SHAREDLIBRARY
# TBB_FOUND, If false, do not try to use TBB.
# TBB_ROOT, if this module use this path to find TBB header
# and libraries.
#
# In Windows, it looks for TBB_DIR environment variable if defined

# Get native target architecture
include(CheckSymbolExists)
if(MSVC)
  check_symbol_exists("_M_AMD64" "" RTC_ARCH_X64)
  if(NOT RTC_ARCH_X64)
    check_symbol_exists("_M_IX86" "" RTC_ARCH_X86)
  endif(NOT RTC_ARCH_X64)
  # add check for arm here
  # see http://msdn.microsoft.com/en-us/library/b0084kay.aspx
else(MSVC)
  check_symbol_exists("__x86_64__" "" RTC_ARCH_X64)
  if(NOT RTC_ARCH_X64)
    check_symbol_exists("__i386__" "" RTC_ARCH_X86)
  endif(NOT RTC_ARCH_X64)
endif(MSVC)

if(RTC_ARCH_X64)
  set(ARCH_STR intel64)
elseif(RTC_ARCH_X86)
  set(ARCH_STR ia32)
else()
  message(FATAL_ERROR "Unknown or unsupported architecture")
endif()

# ###################################

# set TBB_ROOT_DIR in cache if not already done so (Windows only)
if (NOT TBB_ROOT_DIR)
  if (WIN32)
    set(TBB_ROOT_DIR "$ENV{ProgramFiles\(x86\)}/IntelSWTools/compilers_and_libraries/windows/tbb")
  else()
    # somethin' different (to be checked)
  endif()

  set(TBB_ROOT_DIR ${TBB_ROOT_DIR} CACHE PATH "TBB installation root path")
endif (NOT TBB_ROOT_DIR)

#####################################

include (GNUInstallDirs) # defines CMAKE_INSTALL_LIBDIR & CMAKE_INSTALL_INCLUDEDIR

# Find header file
find_path(TBB_INCLUDE_DIR tbb/tbb.h
    PATHS         ${TBB_ROOT_DIR}
    PATH_SUFFIXES include
    DOC           "Location of TBB header files"
)

# Determine the library path
if (WIN32)
  if (MSVC_VERSION VERSION_GREATER_EQUAL 1910)
    set(tbb_lib_suffix vc14_uwp)
  elseif (MSVC_VERSION VERSION_GREATER_EQUAL 1900)
    set(tbb_lib_suffix vc14)
  elseif (MSVC_VERSION VERSION_GREATER_EQUAL 1800)
    set(tbb_lib_suffix vc12)
  else()
    set(tbb_lib_suffix vc_mt)
  endif()
elseif(UNIX)
  set(tbb_lib_suffix ${ARCH_STR})
  if (CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL 4.4)
    set(tbb_lib_suffix gcc4.4)
  else()
    set(tbb_lib_suffix gcc4.1)
  endif()
endif (WIN32)

set(libname tbb)
if (CMAKE_BUILD_TYPE STREQUAL Debug)
  set(libname "${libname}_debug")
endif()

if (WIN32 AND NOT TBB_RUNTIME_LIBRARY_DIR)
  find_path(TBB_RUNTIME_LIBRARY_DIR tbb.dll
            PATHS      "$ENV{ProgramFiles\(x86\)}/IntelSWTools/compilers_and_libraries/windows/redist/${ARCH_STR}/tbb"
            PATH_SUFFIXES ${tbb_lib_suffix}
            DOC        "TBB Runtime Library Path" NO_DEFAULT_PATH)
endif (WIN32 AND NOT TBB_RUNTIME_LIBRARY_DIR)

list(FIND TBB_FIND_COMPONENTS DEBUG _debug_index)
if (DEFINED _debug_index)
  list(REMOVE_ITEM TBB_FIND_COMPONENTS DEBUG)
  set(TBB_DEBUG_FOUND true)
endif(DEFINED _debug_index)

# separate requested components into linking & threading
list(APPEND TBB_FIND_COMPONENTS TBB)
foreach(component IN LISTS TBB_FIND_COMPONENTS)
  if (component STREQUAL TBB)
    set(_var_name TBB)
    set(libname "tbb")
  else()
    set(_var_name "TBB_${component}")
    if (component STREQUAL MALLOC)
      set(libname "tbbmalloc")
    elseif (component STREQUAL PREVIEW)
      set(libname "tbb_preview")
    elseif (component STREQUAL MALLOC_PROXY)
      if (APPLE)
        message(FATAL_ERROR "${component} COMPONENT is not available for OSX.")
      endif()
      set(libname "tbbmalloc_proxy")
    else()
      message(FATAL_ERROR "Invalid COMPONENT (${component}) specified.")
    endif()
  endif()

  find_library("${_var_name}_LIBRARY" ${libname}
    PATHS         ${TBB_ROOT_DIR} 
    PATH_SUFFIXES "lib/${ARCH_STR}/${tbb_lib_suffix}"
    DOC           "TBB ${libname} library path")

  if (TBB_DEBUG_FOUND)  
    find_library("${_var_name}_DEBUG_LIBRARY" "${libname}_debug"
      PATHS         ${TBB_ROOT_DIR} 
      PATH_SUFFIXES "lib/${ARCH_STR}/${tbb_lib_suffix}"
    DOC           "TBB ${libname} debug library path")
  endif (TBB_DEBUG_FOUND)  

endforeach(component IN LISTS TBB_FIND_COMPONENTS)

list(REMOVE_ITEM TBB_FIND_COMPONENTS TBB)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(TBB
    REQUIRED_VARS TBB_INCLUDE_DIR TBB_LIBRARY
    HANDLE_COMPONENTS
)

if (TBB_FOUND)
    list(APPEND TBB_INCLUDE_DIRS ${TBB_INCLUDE_DIR})
    list(APPEND TBB_LIBRARIES ${TBB_LIBRARY} ${TBB_MALLOC_LIBRARY} ${TBB_PREVIEW_LIBRARY} ${TBB_MALLOC_PROXY_LIBRARY})
    if (TBB_DEBUG_FOUND)
      list(APPEND TBB_DEBUG_LIBRARIES ${TBB_DEBUG_LIBRARY} 
                                      ${TBB_MALLOC_DEBUG_LIBRARY} 
                                      ${TBB_PREVIEW_DEBUG_LIBRARY} 
                                      ${TBB_MALLOC_PROXY_DEBUG_LIBRARY})
    endif (TBB_DEBUG_FOUND)
endif (TBB_FOUND)

mark_as_advanced(
  TBB_INCLUDE_DIR
  TBB_LIBRARY
  TBB_MALLOC_LIBRARY
  TBB_MALLOC_PROXY_LIBRARY
  TBB_PREVIEW_LIBRARY
  TBB_RUNTIME_LIBRARY_DIR
)
