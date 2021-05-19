cmake_minimum_required(VERSION 3.13.1)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(hello_world)

target_sources(app PRIVATE src/main.c)


# Additional build flags to work around JerryScript warnings
set(jerry_cflags " \
 -Wno-conversion \
 -Wno-implicit-function-declaration \
 -Wno-old-style-declaration \
 -Wno-pedantic \
 -Wno-shadow \
 -Wno-sign-compare \
 -Wno-sign-conversion \
 -Wno-undef \
 -Wno-unused-parameter \
 -Wno-unused-variable \
 -Wno-dev"
)

if(POLICY CMP0116)
  cmake_policy(SET CMP0116 NEW)
endif()

# The external static library that we are linking with does not know
# how to build for this platform so we export all the flags used in
# this zephyr build to the external build system.
#
# Other external build systems may be self-contained enough that they
# do not need any build information from zephyr. Or they may be
# incompatible with certain zephyr options and need them to be
# filtered out.
zephyr_get_include_directories_for_lang_as_string(       C includes)
zephyr_get_system_include_directories_for_lang_as_string(C system_includes)
zephyr_get_compile_definitions_for_lang_as_string(       C definitions)
zephyr_get_compile_options_for_lang_as_string(           C options)

set(external_project_cflags
  "${includes} ${definitions} ${options} ${system_includes} ${jerry_cflags}"
  )

include(ExternalProject)

# Add an external project to be able download and build the third
# party library. In this case downloading is not necessary as it has
# been committed to the repository.
set(jerry_src_dir   ${CMAKE_CURRENT_SOURCE_DIR}/jerryscript)
set(jerry_build_dir ${CMAKE_CURRENT_BINARY_DIR}/jerryscript)

set(JERRY_LIB_DIR     ${jerry_build_dir}/lib)
# set(JERRY_INCLUDE_DIR ${mylib_src_dir}/include)

set(CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=MinSizeRel
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DEXTERNAL_COMPILE_FLAGS=${external_project_cflags}
)


ExternalProject_Add(
  jerry_project                 # Name for custom target
  PREFIX     ${jerry_build_dir} # Root dir for entire project
  SOURCE_DIR ${jerry_src_dir}
  BINARY_DIR ${jerry_src_dir} # This particular build system is invoked from the root
  CONFIGURE_COMMAND ""    # Skip configuring the project, e.g. with autoconf
  BUILD_COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS}
  COMMAND cd ${JERRY_LIB_DIR}
  COMMAND make jerry-core jerry-ext -j4
  INSTALL_COMMAND ""      # This particular build system has no install command
  BUILD_BYPRODUCTS ${JERRY_LIB_DIR}/libjerry.a
  )

# Create a wrapper CMake library that our app can link with
add_library(jerry-core STATIC IMPORTED)
add_dependencies(jerry-core jerry_project)
set_target_properties(jerry-core PROPERTIES IMPORTED_LOCATION ${JERRY_LIB_DIR}/libjerry-core.a)

add_library(jerry-ext STATIC IMPORTED)
add_dependencies(jerry-ext jerry_project)
set_target_properties(jerry-ext PROPERTIES IMPORTED_LOCATION ${JERRY_LIBDIR}/libjerry-ext.a)

target_link_libraries(app PUBLIC jerry-core jerry-ext)
