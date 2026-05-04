cmake_minimum_required(VERSION 3.10)
project(DNASearch)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include_directories(src)

set(SOURCES
    src/main.cpp
    src/suffix_array.cpp
    src/segment_tree.cpp
    src/hash_cache.cpp
    src/mmap_reader.cpp
    src/input.cpp
    src/output.cpp
)

add_executable(dna_search ${SOURCES})

enable_testing()

set(TEST_SOURCES_COMMON
    src/suffix_array.cpp
    src/segment_tree.cpp
    src/hash_cache.cpp
    src/mmap_reader.cpp
    src/input.cpp
    src/output.cpp
)

add_executable(test_suffix_array tests/test_suffix_array.cpp ${TEST_SOURCES_COMMON})
add_executable(test_segment_tree tests/test_segment_tree.cpp ${TEST_SOURCES_COMMON})
add_executable(test_cache        tests/test_cache.cpp        ${TEST_SOURCES_COMMON})
add_executable(test_complement   tests/test_complement.cpp   ${TEST_SOURCES_COMMON})
add_executable(test_integration  tests/test_integration.cpp  ${TEST_SOURCES_COMMON})

add_test(NAME SuffixArray  COMMAND test_suffix_array)
add_test(NAME SegmentTree  COMMAND test_segment_tree)
add_test(NAME Cache        COMMAND test_cache)
add_test(NAME Complement   COMMAND test_complement)
add_test(NAME Integration  COMMAND test_integration)