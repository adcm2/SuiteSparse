#-------------------------------------------------------------------------------
# SuiteSparse/SuiteSparse_config/CMakeLists.txt:  cmake for SuiteSparse_config
#-------------------------------------------------------------------------------

# SuiteSparse_config, Copyright (c) 2012-2023, Timothy A. Davis.
# All Rights Reserved.
# SPDX-License-Identifier: BSD-3-clause

#-------------------------------------------------------------------------------
# get the version
#-------------------------------------------------------------------------------

# cmake 3.22 is required to find the BLAS
cmake_minimum_required ( VERSION 3.22 )

# version of both SuiteSparse and SuiteSparse_config
set ( SUITESPARSE_DATE "Dec 30, 2023" )
set ( SUITESPARSE_VERSION_MAJOR 7 )
set ( SUITESPARSE_VERSION_MINOR 4 )
set ( SUITESPARSE_VERSION_SUB   0 )
set ( SUITESPARSE_CONFIG_VERSION_MAJOR ${SUITESPARSE_VERSION_MAJOR} CACHE STRING "" FORCE )
set ( SUITESPARSE_CONFIG_VERSION_MINOR ${SUITESPARSE_VERSION_MINOR} CACHE STRING "" FORCE )
set ( SUITESPARSE_CONFIG_VERSION_PATCH ${SUITESPARSE_VERSION_SUB} CACHE STRING "" FORCE )

message ( STATUS "Building SuiteSparse_config version: v"
    ${SUITESPARSE_VERSION_MAJOR}.
    ${SUITESPARSE_VERSION_MINOR}.
    ${SUITESPARSE_VERSION_SUB} " (" ${SUITESPARSE_DATE} ")" )

#-------------------------------------------------------------------------------
# define the project
#-------------------------------------------------------------------------------

project ( SuiteSparseConfig
    VERSION "${SUITESPARSE_VERSION_MAJOR}.${SUITESPARSE_VERSION_MINOR}.${SUITESPARSE_VERSION_SUB}"
    LANGUAGES C )

#-------------------------------------------------------------------------------
# SuiteSparse policies
#-------------------------------------------------------------------------------

set ( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
    ${PROJECT_SOURCE_DIR}/cmake_modules )

include ( SuiteSparsePolicy )

if ( NOT NFORTRAN )
    include ( FortranCInterface )
else ( )
    # No Fortran compiler available or enabled, configuration is not automatic.
    set ( FortranCInterface_GLOBAL_MACRO  ${SUITESPARSE_C_TO_FORTRAN} )
    set ( FortranCInterface_GLOBAL__MACRO ${SUITESPARSE_C_TO_FORTRAN} )
endif ( )

#-------------------------------------------------------------------------------
# find library dependencies
#-------------------------------------------------------------------------------

option ( NOPENMP "ON: do not use OpenMP.  OFF (default): use OpenMP" OFF )
if ( NOPENMP )
    # OpenMP has been disabled
    message ( STATUS "OpenMP disabled" )
    set ( OpenMP_C_FOUND OFF )
else ( )
    find_package ( OpenMP )
endif ( )

include ( SuiteSparseBLAS )

#-------------------------------------------------------------------------------
# configure files
#-------------------------------------------------------------------------------

configure_file ( "Config/SuiteSparse_config.h.in"
    "${PROJECT_SOURCE_DIR}/SuiteSparse_config.h"
    NEWLINE_STYLE LF )

configure_file ( "Config/README.md.in"
    "${PROJECT_SOURCE_DIR}/../README.md"
    NEWLINE_STYLE LF )

#-------------------------------------------------------------------------------
# dynamic SuiteSparseConfig library properties
#-------------------------------------------------------------------------------

file ( GLOB SUITESPARSECONFIG_SOURCES "*.c" )

if ( BUILD_SHARED_LIBS )
    add_library ( SuiteSparseConfig SHARED ${SUITESPARSECONFIG_SOURCES} )

    set_target_properties ( SuiteSparseConfig PROPERTIES
        VERSION ${SUITESPARSE_VERSION_MAJOR}.${SUITESPARSE_VERSION_MINOR}.${SUITESPARSE_VERSION_SUB}
        C_STANDARD 11
        C_STANDARD_REQUIRED ON
        OUTPUT_NAME suitesparseconfig
        SOVERSION ${SUITESPARSE_VERSION_MAJOR}
        PUBLIC_HEADER "SuiteSparse_config.h"
        WINDOWS_EXPORT_ALL_SYMBOLS ON )

    if ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25" )
        set_target_properties ( SuiteSparseConfig PROPERTIES EXPORT_NO_SYSTEM ON )
    endif ( )

    target_include_directories ( SuiteSparseConfig
        INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                  $<INSTALL_INTERFACE:${SUITESPARSE_INCLUDEDIR}> )
endif ( )

#-------------------------------------------------------------------------------
# static SuiteSparseConfig library properties
#-------------------------------------------------------------------------------

if ( BUILD_STATIC_LIBS )
    add_library ( SuiteSparseConfig_static STATIC ${SUITESPARSECONFIG_SOURCES} )

    set_target_properties ( SuiteSparseConfig_static PROPERTIES
        C_STANDARD 11
        C_STANDARD_REQUIRED ON
        OUTPUT_NAME suitesparseconfig
        PUBLIC_HEADER "SuiteSparse_config.h" )

    if ( MSVC )
        set_target_properties ( SuiteSparseConfig_static PROPERTIES
            OUTPUT_NAME suitesparseconfig_static )
    endif ( )

    if ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25" )
        set_target_properties ( SuiteSparseConfig_static PROPERTIES EXPORT_NO_SYSTEM ON )
    endif ( )

    target_include_directories ( SuiteSparseConfig_static
        INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                  $<INSTALL_INTERFACE:${SUITESPARSE_INCLUDEDIR}> )
endif ( )

#-------------------------------------------------------------------------------
# add the library dependencies
#-------------------------------------------------------------------------------

# libm:
if ( NOT WIN32 )
    if ( BUILD_SHARED_LIBS )
        target_link_libraries ( SuiteSparseConfig PRIVATE m )
    endif ( )
    if ( BUILD_STATIC_LIBS )
        target_link_libraries ( SuiteSparseConfig_static PUBLIC m )
    endif ( )
endif ( )

# OpenMP:
if ( OpenMP_C_FOUND )
    message ( STATUS "OpenMP C libraries:      ${OpenMP_C_LIBRARIES} ")
    message ( STATUS "OpenMP C include:        ${OpenMP_C_INCLUDE_DIRS} ")
    message ( STATUS "OpenMP C flags:          ${OpenMP_C_FLAGS} ")
    if ( BUILD_SHARED_LIBS )
        target_link_libraries ( SuiteSparseConfig PRIVATE OpenMP::OpenMP_C )
        target_include_directories ( SuiteSparseConfig SYSTEM AFTER INTERFACE
            "$<TARGET_PROPERTY:OpenMP::OpenMP_C,INTERFACE_INCLUDE_DIRECTORIES>" )
    endif ( )
    if ( BUILD_STATIC_LIBS )
        target_link_libraries ( SuiteSparseConfig_static PRIVATE OpenMP::OpenMP_C )
        target_include_directories ( SuiteSparseConfig_static SYSTEM AFTER INTERFACE
            "$<TARGET_PROPERTY:OpenMP::OpenMP_C,INTERFACE_INCLUDE_DIRECTORIES>" )
    endif ( )
endif ( )

# BLAS:
if ( BLAS_FOUND )
    # SuiteSparse_config does not itself require the BLAS.  It just needs to
    # know which BLAS is going to be used by the rest of SuiteSparse so it
    # can configure SuiteSparse_config.h properly.
    message ( STATUS "BLAS libraries:      ${BLAS_LIBRARIES} ")
    message ( STATUS "BLAS linker flags:   ${BLAS_LINKER_FLAGS} ")
    message ( STATUS "BLAS include:        ${BLAS_INCLUDE_DIRS} ")
endif ( )

#-------------------------------------------------------------------------------
# SuiteSparseConfig installation location
#-------------------------------------------------------------------------------

include ( CMakePackageConfigHelpers )

file ( GLOB SUITESPARSE_CMAKE_MODULES "cmake_modules/*" )

if ( BUILD_SHARED_LIBS )
    install ( TARGETS SuiteSparseConfig
        EXPORT SuiteSparse_configTargets
        LIBRARY DESTINATION ${SUITESPARSE_LIBDIR}
        ARCHIVE DESTINATION ${SUITESPARSE_LIBDIR}
        RUNTIME DESTINATION ${SUITESPARSE_BINDIR}
        PUBLIC_HEADER DESTINATION ${SUITESPARSE_INCLUDEDIR} )
endif ( )
if ( BUILD_STATIC_LIBS )
    install ( TARGETS SuiteSparseConfig_static
        EXPORT SuiteSparse_configTargets
        ARCHIVE DESTINATION ${SUITESPARSE_LIBDIR}
        PUBLIC_HEADER DESTINATION ${SUITESPARSE_INCLUDEDIR} )
endif ( )
install ( FILES
    ${SUITESPARSE_CMAKE_MODULES}
    DESTINATION ${SUITESPARSE_PKGFILEDIR}/cmake/SuiteSparse
    COMPONENT Development )

# create (temporary) export target file during build
export ( EXPORT SuiteSparse_configTargets
    NAMESPACE SuiteSparse::
    FILE ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_configTargets.cmake )

# install export target and config for find_package
install ( EXPORT SuiteSparse_configTargets
    NAMESPACE SuiteSparse::
    DESTINATION ${SUITESPARSE_PKGFILEDIR}/cmake/SuiteSparse_config )

configure_package_config_file (
    Config/SuiteSparse_configConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_configConfig.cmake
    INSTALL_DESTINATION ${SUITESPARSE_PKGFILEDIR}/cmake/SuiteSparse_config )

write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_configConfigVersion.cmake
    COMPATIBILITY SameMajorVersion )

install ( FILES
    ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_configConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_configConfigVersion.cmake
    DESTINATION ${SUITESPARSE_PKGFILEDIR}/cmake/SuiteSparse_config )

#-------------------------------------------------------------------------------
# create pkg-config file
#-------------------------------------------------------------------------------

if ( NOT MSVC )
    set ( prefix "${CMAKE_INSTALL_PREFIX}" )
    set ( exec_prefix "\${prefix}" )
    cmake_path ( IS_ABSOLUTE SUITESPARSE_LIBDIR SUITESPARSE_LIBDIR_IS_ABSOLUTE )
    if (SUITESPARSE_LIBDIR_IS_ABSOLUTE)
        set ( libdir "${SUITESPARSE_LIBDIR}")
    else ( )
        set ( libdir "\${exec_prefix}/${SUITESPARSE_LIBDIR}")
    endif ( )
    cmake_path ( IS_ABSOLUTE SUITESPARSE_INCLUDEDIR SUITESPARSE_INCLUDEDIR_IS_ABSOLUTE )
    if (SUITESPARSE_INCLUDEDIR_IS_ABSOLUTE)
        set ( includedir "${SUITESPARSE_INCLUDEDIR}")
    else ( )
        set ( includedir "\${prefix}/${SUITESPARSE_INCLUDEDIR}")
    endif ( )
    if ( BUILD_SHARED_LIBS )
        set ( SUITESPARSE_LIB_BASE_NAME $<TARGET_FILE_BASE_NAME:SuiteSparseConfig> )
    else ( )
        set ( SUITESPARSE_LIB_BASE_NAME $<TARGET_FILE_BASE_NAME:SuiteSparseConfig_static> )
    endif ( )
    configure_file (
        Config/SuiteSparse_config.pc.in
        SuiteSparse_config.pc.out
        @ONLY
        NEWLINE_STYLE LF )
    file ( GENERATE
        OUTPUT SuiteSparse_config.pc
        INPUT ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_config.pc.out
        NEWLINE_STYLE LF )
    install ( FILES
        ${CMAKE_CURRENT_BINARY_DIR}/SuiteSparse_config.pc
        DESTINATION ${SUITESPARSE_PKGFILEDIR}/pkgconfig )
endif ( )

#-------------------------------------------------------------------------------
# report status
#-------------------------------------------------------------------------------

if ( NOT SUITESPARSE_ROOT_CMAKELISTS )
    include ( SuiteSparseReport )
endif ( )
