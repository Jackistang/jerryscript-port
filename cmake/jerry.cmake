# Copyright (c) 2017, Intel Corporation.

include(ExternalProject)

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
 -Wno-unused-variable"
)

zephyr_get_include_directories_for_lang_as_string(C includes)
zephyr_get_system_include_directories_for_lang_as_string(C system_includes)
zephyr_get_compile_definitions_for_lang_as_string(C definitions)
zephyr_get_compile_options_for_lang_as_string(C options)


set(external_project_cflags
  "${includes} ${definitions} ${options} ${system_includes} ${jerry_cflags} ${net_includes}"
  )

set(jerry_src_dir   ${CMAKE_CURRENT_SOURCE_DIR}/jerryscript)
set(jerry_build_dir ${CMAKE_CURRENT_BINARY_DIR}/jerryscript)

set(JERRY_LIBDIR     ${jerry_build_dir}/lib)
# set(jerry_INCLUDE_DIR ${jerry_src_dir}/include)


set(CMAKE_ARGS
  -B${JERRY_LIBDIR}
  -DCMAKE_BUILD_TYPE=MinSizeRel
  -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
  -DCMAKE_C_COMPILER_WORKS=TRUE
  -DCMAKE_SYSTEM_NAME=Zephyr
  -DENABLE_ALL_IN_ONE=OFF
  -DENABLE_LTO=ON
  -DEXTERNAL_COMPILE_FLAGS=${external_project_cflags}
  -DFEATURE_ERROR_MESSAGES=ON
  -DFEATURE_DEBUGGER=${DEBUGGER}
  -DFEATURE_INIT_FINI=ON
  -DFEATURE_PROFILE=${JERRY_PROFILE}
  -DFEATURE_SNAPSHOT_EXEC=OFF
  -DFEATURE_VALGRIND=OFF
  -DJERRY_CMDLINE=OFF
  -DJERRY_LIBC=OFF
  -DJERRY_LIBM=OFF
  -DJERRY_PORT_DEFAULT=OFF
  -DMEM_HEAP_SIZE_KB=${JERRY_HEAP}
  -H${JERRY_BASE}
)

# build libjerry as a static library
ExternalProject_Add(
  jerry_project
  PREFIX     ${jerry_build_dir}
  SOURCE_DIR ${jerry_src_dir}
  BINARY_DIR ${jerry_src_dir}
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS}
  COMMAND cd ${JERRY_LIBDIR}
  COMMAND make jerry-core jerry-ext -j4
  INSTALL_COMMAND ""
  )

add_library(jerry-core STATIC IMPORTED)
add_dependencies(jerry-core jerry_project)
set_target_properties(jerry-core PROPERTIES IMPORTED_LOCATION ${JERRY_LIBDIR}/lib/libjerry-core.a)

add_library(jerry-ext STATIC IMPORTED)
add_dependencies(jerry-ext jerry_project)
set_target_properties(jerry-ext PROPERTIES IMPORTED_LOCATION ${JERRY_LIBDIR}/lib/libjerry-ext.a)
