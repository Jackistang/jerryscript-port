cmake_minimum_required(VERSION 3.20)

project(mylib)

add_library(mylib STATIC
    src/mylib.c)

target_include_directories(mylib
    PUBLIC
    ${PROJECT_SOURCE_DIR}/include)