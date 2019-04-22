#.rst:
# FindIPP
# -------
# Find the IPP include directory and libraries
#
# The module supports the following components:
#
#    STATIC_LINKING         
#    DYNAMIC_LINKING        
#
#    SEQUENTIAL_THREADING - sequential execution, not relying on any threading library
#    OPENMP_THREADING     - using Intel OpenMP library
#    TBB_THREADING        - using Intel TBB library
#
#    COLOR_CONVERSION
#    STRING_OPERATION
#    CRYPTOGRAPHY
#    COMPUTER_VISION
#    DATA_COMPRESSION
#    IMAGE_PROCESSING
#    SIGNAL_PROCESSING
#    VECTOR_MATH
#    ALL_DOMAINS - may not load cryptography
#
# Only 1 Linking Component (STATIC_LINKING or DYNAMIC_LINKING) may be specified.
#
# Only 1 Threading Component (SEQUENTIAL_THREADING, OPENMP_THREADING, or 
# TBB_THREADING) may be specified. If multi-threading option (OPENMP_THREADING 
# or TBB_THREADING) is selected, the selected threading library must be added
# separately from IPP.
#
# Module Input Variables
# ^^^^^^^^^^^^^^^^^^^^^^
#
# Users or projects may set the following variables to configure the module
# behaviour:
#
# Result variables
# """"""""""""""""
# ``IPP_FOUND``
#   ``TRUE`` if the IPP installation and runtime files are found, ``FALSE``
#   otherwise. All variable below are defined if IPP is found.
# ``IPP_INCLUDE_DIR`` or ``IPP_INCLUDE_DIRS`` (Cached)
#  the path of the IPP header files (checks for IPP.h)
# ``IPP_LIBRARIES`` (Cached)
#   the set of all the libraries
# ``IPP_FOUND``
#   ``TRUE`` if all the pieces of IPP is found, ``FALSE`` otherwise
# ``IPP_LINKING_FOUND``
#   ``TRUE`` if the IPP library is found for the requested linking, ``FALSE`` 
#   otherwise. Only created if XXX_LINKING component is given.
# ``IPP_THREADING_FOUND``
#   ``TRUE`` if the IPP library is found for the requested threading library 
#   support, ``FALSE`` otherwise. Only created if XXX_THREADING component is 
#   given.

#                 Single-threaded                           Threading Layer   
#                 (non-threaded)                            (externally threaded)
#-----------------------------------------------------------------------------------------------------------
#Description      Suitable for application-level threading 	Implementation of application-level threading
#                                                           depends on single-threaded libraries
#Found in 	      Main package                              Main package
#                 After installation:                       After installation: 
#                   <ipp directory>/lib/<arch>                <ipp directory>/lib/<arch>/tl/<threading_type>
#                                                           where <threading_type> is one of {tbb, openmp}
#Static linking   Windows* OS:                              Windows* OS: 
#                   mt suffix in a library name               mt suffix in a library name (ipp<domain>mt_tl.lib)
#                   (ipp<domain>st.lib)                     Linux* OS and macOS*: no suffix in a library name 
#                 Linux* OS and macOS*: no suffix in          (libipp<domain>_tl.a)
#                 a library name (libipp<domain>.a)         + single-threaded libraries dependency
#Dynamic Linking  Default (no suffix)                       _tl suffix
#                 Windows* OS: ipp<domain>.lib              Windows* OS: ipp<domain>_tl.lib
#                 Linux* OS: libipp<domain>.a               Linux* OS: libipp<domain>_tl.a
#                 macOS*: libipp<domain>.dylib              macOS*: libipp<domain>_tl.dylib
#                                                           + single-threaded library dependency

#To switch between Intel IPP libraries, set the path to the preferred library in system variables or in your project, for example:
#  Windows* OS:
#   Single-threaded: SET LIB=<ipp directory>/lib/<arch>
#   Threading Layer: SET LIB=<ipp directory>/lib/<arch>/tl/<threading_type>. Additionally, set path to single-threaded libraries: SET LIB=<ipp directory>/lib/<arch>
#  Linux* OS/macOS*
#   Single-threaded: gcc <options> -L <ipp directory>/lib/<arch>
#   Threading Layer: gcc <options> -L <ipp directory>/lib/<arch>/tl<threading_type>. Additionally, set path to single-threaded libraries: gcc <options> -L <ipp directory>/lib/<arch>


#Library Dependencies by Domain
# Domain            Domain Code   Depends on
#Color Conversion   CC            Core, VM, S, I
#String Operations  CH            Core, VM, S
#Cryptography       CP            Core
#Computer Vision    CV            Core, VM, S, I
#Data Compression   DC            Core, VM, S
#Image Processing   I             Core, VM, S
#Signal Processing  S             Core, VM
#Vector Math        VM            Core
#
#ref: https://software.intel.com/en-us/ipp-dev-guide-library-dependencies-by-domain


# Get native target architecture
include(CheckSymbolExists)
# http://beefchunk.com/documentation/lang/c/pre-defined-c/prearch.html
if(MSVC)
  check_symbol_exists("_M_AMD64" "" RTC_ARCH_X64)
  if(NOT RTC_ARCH_X64)
    check_symbol_exists("_M_IX86" "" RTC_ARCH_X86)
  endif(NOT RTC_ARCH_X64)
  # add check for arm here
  # see http://msdn.microsoft.com/en-us/library/b0084kay.aspx
elseif(MINGW)
    check_symbol_exists("_X86_WIN64_" "" RTC_ARCH_X64)
    if(NOT RTC_ARCH_X64)
    check_symbol_exists("_X86_" "" RTC_ARCH_X86)
    endif(NOT RTC_ARCH_X64)
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

# separate requested components into linking & threading
foreach(component IN LISTS IPP_FIND_COMPONENTS)
  if (component MATCHES .+_LINKING)
    list(APPEND linking_component ${component})
  elseif (component MATCHES .+_THREADING)
    list(APPEND threading_component ${component})
  elseif (component MATCHES .+_DOMAIN)
    list(APPEND domain_component ${component})
  else()
    message(FATAL_ERROR "Unknown IPP component (${component}) specified.")
  endif()
endforeach(component IN LISTS IPP_FIND_COMPONENTS)

# only 1 LINKING component maybe requested
if (linking_component)
  list(LENGTH linking_component num_comp)
  if (${num_comp} GREATER 1)
    message(FATAL_ERROR "Cannot set multiple LINKING components.")
  endif()
else()
  set(linking_component "DYNAMIC_LINKING") # default linking
endif()

# only 1 THREADING component maybe requested
if (threading_component)
  list(LENGTH threading_component num_comp)
  if (${num_comp} GREATER 1)
    message(FATAL_ERROR "Cannot set multiple THREADING components.")
  endif()
endif (threading_component)
if(NOT threading_component)
  set(threading_component "SEQUENTIAL_THREADING") # default threading
endif()

# ###################################

# set IPP_ROOT_DIR in cache if not already done so (Windows only)
if (NOT IPP_ROOT_DIR)
  if (EXISTS $ENV{IPPROOT})
    set(IPP_ROOT_DIR $ENV{IPPROOT} CACHE PATH "IPP installation root path")
  else()
    set(IPP_ROOT_DIR "$ENV{ProgramFiles\(x86\)}/IntelSWTools/compilers_and_libraries/windows/ipp" CACHE PATH "IPP installation root path")
  endif()
endif (NOT IPP_ROOT_DIR)

#####################################

include (GNUInstallDirs) # defines CMAKE_INSTALL_LIBDIR & CMAKE_INSTALL_INCLUDEDIR

# Find header file
find_path(IPP_INCLUDE_DIR ipp.h
    PATHS         ${IPP_ROOT_DIR}
    PATH_SUFFIXES include
    DOC           "Location of IPP header files"
)

# check domain components & create list of domain codes to include
list(APPEND domain_codes "core")
list(APPEND _req_vars IPP_CORE_FOUND)
foreach(domain IN LISTS domain_component)
  if (domain STREQUAL COLOR_CONVERSION)
    list(JOIN ";" ${domain_codes} "cc" "vm" "s" "i")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
    list(APPEND _req_vars IPP_SIGNAL_PROCESSING_FOUND)
    list(APPEND _req_vars IMAGE_PROCESSING_FOUND)
  elseif (domain STREQUAL STRING_OPERATION)
    list(JOIN ";" ${domain_codes} "ch" "vm" "s")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
    list(APPEND _req_vars IPP_SIGNAL_PROCESSING_FOUND)
  elseif (domain STREQUAL CRYPTOGRAPHY)
    list(JOIN ";" ${domain_codes} "cp")
  elseif (domain STREQUAL COMPUTER_VISION)
    list(JOIN ";" ${domain_codes} "cv" "vm" "s" "i")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
    list(APPEND _req_vars IPP_SIGNAL_PROCESSING_FOUND)
    list(APPEND _req_vars IPP_IMAGE_PROCESSING_FOUND)
  elseif (domain STREQUAL DATA_COMPRESSION)
    list(JOIN ";" ${domain_codes} "dc" "vm" "s")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
    list(APPEND _req_vars IPP_SIGNAL_PROCESSING_FOUND)
  elseif (domain STREQUAL IMAGE_PROCESSING)
    list(JOIN ";" ${domain_codes} "i" "vm" "s")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
    list(APPEND _req_vars IPP_SIGNAL_PROCESSING_FOUND)
  elseif (domain STREQUAL SIGNAL_PROCESSING)
    list(JOIN ";" ${domain_codes} "s" "vm")
    list(APPEND _req_vars IPP_VECTOR_MATH_FOUND)
  elseif (domain STREQUAL VECTOR_MATH)
    list(JOIN ";" ${domain_codes} "vm")
  elseif (domain STREQUAL "ALL_DOMAINS")
    set(domain_codes "core;cc;ch;cp;cv;dc;i;s;vm")
  else()
    message(FATAL_ERROR "Unknown IPP component: ${domain}")
  endif()
endforeach()
list(REMOVE_DUPLICATES domain_codes)

# Set single-thread library suffix
if (WIN32 AND linking_component STREQUAL STATIC_LINKING)
  set(lib_suffix "mt")
else()
  set(lib_suffix "")
endif()

# get list of single-thread libraries
message(STATUS "domain=${domain}")
set(lib_path_suffix "lib/${ARCH_STR}")
foreach(domain IN LISTS domain_codes)
  set(domainlib "IPP_${domain}_LIBRARY")
  find_library(${domainlib} "ipp${domain}${lib_suffix}"
               PATHS         ${IPP_ROOT_DIR} 
               PATH_SUFFIXES ${lib_path_suffix})

  if (${domainlib})
    list(APPEND lib_list ${domainlib})
    list(APPEND lib_found ${domain})
  endif()

  # find dll files in windows
  if (WIN32 AND DYNAMIC_LINKING)
    set(dll_path "$ENV{ProgramFiles\(x86\)}/IntelSWTools/compilers_and_libraries/windows/redist/${ARCH_STR}/ipp")
    set(dll_name "ipp${domain}${lib_suffix}.dll")
    set(domain_dll "IPP_${domain}_RUNTIME_LIBRARY")
    find_file(${domain_dll} ${dll_name} PATHS ${dll_path})
    if (${domain_dll})
      list(APPEND dll_list ${domain_dll})
    else()
      message("${dll_name} not found.")
    endif()
  endif (WIN32 AND DYNAMIC_LINKING)
endforeach()

if (NOT threading_component STREQUAL SEQUENTIAL_THREADING)
  # also find multi-thread libraries
  set(lib_suffix "${lib_suffix}_tl")
  if (threading_component STREQUAL OPENMP_THREADING)
    set(lib_path_suffix "${lib_suffix}/tl/openmp")
  else() #TBB
    set(lib_path_suffix "${lib_suffix}/tl/tbb")
  endif()

  foreach(domain IN LISTS domain_codes)
    set(domainlib "IPP_${domain}_MT_LIBRARY")
    find_library(${domainlib} "ipp${domain}${lib_suffix}"
                PATHS         ${IPP_ROOT_DIR} 
                PATH_SUFFIXES ${lib_path_suffix})
    if (${domainlib})
      list(APPEND lib_list ${domainlib})
      list(APPEND mtlib_found ${domain})
    endif()

    if (WIN32 AND DYNAMIC_LINKING)
      set(dll_name "ipp${domain}${lib_suffix}.dll")
      set(domain_dll "IPP_${domain}_MT_RUNTIME_LIBRARY")
      find_file(${domain_dll} ${dll_name} PATHS ${dll_path})
      if (${domainlib})
        list(APPEND dll_list ${domainlib})
      else()
        message("${dll_name} not found.")
      endif()
    endif (WIN32 AND DYNAMIC_LINKING)
  endforeach()
endif()

# report findings
foreach(domain IN LISTS domain_codes)
  if ("IPP_${domain}_LIBRARY" IN_LIST lib_list)
    if (domain STREQUAL "core")
      set(IPP_CORE_FOUND true)
    elseif (domain STREQUAL "cc")
      set(IPP_COLOR_CONVERSION_FOUND true)
    elseif (domain STREQUAL "ch")
      set(IPP_STRING_OPERATION_FOUND true)
    elseif (domain STREQUAL "cp")
      set(IPP_CRYPTOGRAPHY_FOUND true)
    elseif (domain STREQUAL "cv")
      set(IPP_COMPUTER_VISION_FOUND true)
    elseif (domain STREQUAL "dc")
      set(IPP_DATA_COMPRESSION_FOUND true)
    elseif (domain STREQUAL "i")
      set(IPP_IMAGE_PROCESSING_FOUND true)
    elseif (domain STREQUAL "s")
      set(IPP_SIGNAL_PROCESSING_FOUND true)
    elseif (domain STREQUAL "vm")
      set(IPP_VECTOR_MATH_FOUND true)
    endif()
  endif()
endforeach()
if (ALL_DOMAINS IN_LIST domain_component AND IPP_CORE_FOUND AND IPP_COLOR_CONVERSION_FOUND
    AND IPP_STRING_OPERATION_FOUND AND IPP_COMPUTER_VISION_FOUND #AND IPP_CRYPTOGRAPHY_FOUND
    AND IPP_DATA_COMPRESSION_FOUND AND IPP_IMAGE_PROCESSING_FOUND AND IPP_SIGNAL_PROCESSING_FOUND)
  set(IPP_ALL_DOMAINS_FOUND true)
endif()

# mark linking and threading components found if at least on library file is found
if (lib_list)
  if (linking_component)
    set("IPP_${linking_component}_FOUND" true)
  endif()
  message( STATUS ${linking_component}_FOUND)
  if (threading_component)
    set("IPP_${threading_component}_FOUND" true)
  endif()
endif()

include(FindPackageHandleStandardArgs)
list(REMOVE_DUPLICATES _req_vars)
find_package_handle_standard_args(IPP
    REQUIRED_VARS ${_req_vars}
    HANDLE_COMPONENTS
)

if (IPP_FOUND)
  foreach(lib IN LISTS lib_list)
    list(APPEND IPP_LIBRARIES ${${lib}})
  endforeach()
  set(IPP_LIBRARIES ${IPP_LIBRARIES} CACHE FILEPATH "Paths to IPP library files")
  mark_as_advanced(FORCE ${lib_list})

  if (WIN32)
    foreach(lib IN LISTS dll_list)
      list(APPEND IPP_RUNTIME_LIBRARIES ${${lib}})
    endforeach()
    set(IPP_RUNTIME_LIBRARIES ${IPP_RUNTIME_LIBRARIES} CACHE FILEPATH "Paths to IPP runtime library files")
    mark_as_advanced(FORCE ${dll_list})
  endif(WIN32)
endif (IPP_FOUND)
