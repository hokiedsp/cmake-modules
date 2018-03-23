# Find the NLopt include and library
# This module defines
# NLopt_INCLUDE_DIR, where to find nlopt.h
# NLopt_LIBRARY, the library to link against to use NLopt.
# NLopt_SHAREDLIBRARY
# NLopt_FOUND, If false, do not try to use NLopt.
# NLopt_ROOT_DIR, if this module use this path to find NLopt header
# and libraries.
#
# In Windows, it looks for NLopt_DIR environment variable if defined

include(FindPackageHandleStandardArgs)

# ###################################
# Exploring the possible NLopt_ROOT_DIR
if (NOT NLopt_ROOT_DIR)
    set(NLopt_ROOT_DIR $ENV{NLopt_DIR} CACHE PATH "NLopt installation root path")
endif (NOT NLopt_ROOT_DIR)

include (GNUInstallDirs) # defines CMAKE_INSTALL_LIBDIR & CMAKE_INSTALL_INCLUDEDIR

# Find header and lib directories
find_path(NLopt_INCLUDE_DIR nlopt.h
    PATHS ${NLopt_ROOT_DIR}
          "$ENV{ProgramFiles}"
          "$ENV{USERPROFILE}/AppData/Local"
          "$ENV{USERPROFILE}/AppData/Local/Programs"
          "$ENV{USERPROFILE}/AppData/Local/include"
          "$ENV{SystemDrive}"
    PATH_SUFFIXES nlopt/include include
    DOC "Location of NLopt header file"
)

find_library(NLopt_LIBRARY
    NAMES nlopt
    PATHS
        ${NLopt_ROOT_DIR}
        "$ENV{ProgramFiles}"
        "$ENV{USERPROFILE}/AppData/Local"
        "$ENV{USERPROFILE}/AppData/Local/Programs"
        "$ENV{USERPROFILE}/AppData/Local/lib"
        "$ENV{SystemDrive}"
    PATH_SUFFIXES nlopt/lib lib
    DOC "Location of NLopt library"
)

if (WIN32 AND NOT NLopt_RUNTIME_LIBRARY_DIR)
  find_path(NLopt_RUNTIME_LIBRARY_DIR nlopt.dll
            PATHS ${NLopt_ROOT_DIR}
                  ${CMAKE_INSTALL_FULL_LIBDIR}
                  "$ENV{ProgramFiles}"
                  "$ENV{USERPROFILE}/AppData/Local"
                  "$ENV{USERPROFILE}/AppData/Local/Programs"
                  "$ENV{USERPROFILE}/AppData/Local/lib"
                  "$ENV{SystemDrive}"
            PATH_SUFFIXES nlopt/bin bin
            DOC    "NLopt Runtime Library Path" NO_DEFAULT_PATH)
endif (WIN32 AND NOT NLopt_RUNTIME_LIBRARY_DIR)

find_package_handle_standard_args(
  NLopt
  REQUIRED_VARS NLopt_INCLUDE_DIR NLopt_LIBRARY)

if (NLopt_FOUND)
  list(APPEND NLopt_INCLUDE_DIRS ${NLopt_INCLUDE_DIR})
  list(APPEND NLopt_LIBRARIES ${NLopt_LIBRARY})
endif (NLopt_FOUND)

mark_as_advanced(
    NLopt_INCLUDE_DIR
    NLopt_LIBRARY
    NLopt_RUNTIME_LIBRARY_DIR
)
