cmake_minimum_required(VERSION 3.13.1)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(hello_world)

target_sources(app PRIVATE src/main.c)

include(cmake/mylib.cmake)
include(cmake/jerry.cmake)

target_link_libraries(app PUBLIC mylib_lib)
target_link_libraries(app PUBLIC jerry-core jerry-ext)