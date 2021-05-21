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
  "${includes} ${definitions} ${options} ${system_includes}"
  )

include(ExternalProject)

# Add an external project to be able download and build the third
# party library. In this case downloading is not necessary as it has
# been committed to the repository.
set(mylib_src_dir   ${CMAKE_CURRENT_SOURCE_DIR}/mylib)
set(mylib_build_dir ${CMAKE_CURRENT_BINARY_DIR}/mylib)

set(MYLIB_LIB_DIR     ${mylib_build_dir}/lib)
set(MYLIB_INCLUDE_DIR ${mylib_src_dir}/include)

if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
# https://www.gnu.org/software/make/manual/html_node/MAKE-Variable.html
set(submake "$(MAKE)")
else() # Obviously no MAKEFLAGS. Let's hope a "make" can be found somewhere.
set(submake "make")
endif()

ExternalProject_Add(
  mylib_project                 # Name for custom target
  PREFIX     ${mylib_build_dir} # Root dir for entire project
  SOURCE_DIR ${mylib_src_dir}
  BINARY_DIR ${mylib_src_dir} # This particular build system is invoked from the root
  CONFIGURE_COMMAND ""    # Skip configuring the project, e.g. with autoconf
#   BUILD_COMMAND
#   ${submake}
#   PREFIX=${mylib_build_dir}
#   CC=${CMAKE_C_COMPILER}
#   AR=${CMAKE_AR}
#   CFLAGS=${external_project_cflags}
    BUILD_COMMAND cmake -B${MYLIB_LIB_DIR}
    COMMAND cd ${MYLIB_LIB_DIR} && make
  INSTALL_COMMAND ""      # This particular build system has no install command
  BUILD_BYPRODUCTS ${MYLIB_LIB_DIR}/libmylib.a
  )

# Create a wrapper CMake library that our app can link with
add_library(mylib_lib STATIC IMPORTED GLOBAL)
add_dependencies(
  mylib_lib
  mylib_project
  )
set_target_properties(mylib_lib PROPERTIES IMPORTED_LOCATION             ${MYLIB_LIB_DIR}/libmylib.a)
set_target_properties(mylib_lib PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${MYLIB_INCLUDE_DIR})