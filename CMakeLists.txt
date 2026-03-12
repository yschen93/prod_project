cmake_minimum_required(VERSION 3.20)
project(prod_project)


# Set the policy for CMP0077 to NEW to allow set() to override options in subdirectories
cmake_policy(SET CMP0077 NEW)
# Set the policy for CMP0135 to NEW to use the extraction time for the timestamp
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

# Set C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# abseil-cpp
FetchContent_Declare(
  abseil-cpp
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/abseil-cpp-20260107.1.tar.gz
)
set(BUILD_SHARED_LIBS OFF)
set(ABSL_PROPAGATE_CXX_STD ON)
set(ABSL_BUILD_TESTING OFF)
FetchContent_MakeAvailable(abseil-cpp)

# Catch2
FetchContent_Declare(
  Catch2
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/Catch2-3.13.0.tar.gz
)
set(BUILD_SHARED_LIBS ON)
set(CATCH_BUILD_TESTING OFF)
set(CATCH_INSTALL_DOCS OFF)
set(CATCH_INSTALL_EXTRAS OFF)
FetchContent_MakeAvailable(Catch2)

# spdlog
FetchContent_Declare(
  spdlog
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/spdlog-1.17.0.tar.gz
)
set(BUILD_SHARED_LIBS ON)
set(SPDLOG_BUILD_SHARED ON)
set(SPDLOG_BUILD_EXAMPLE OFF)
set(SPDLOG_BUILD_TESTS OFF)
set(SPDLOG_BUILD_BENCH OFF)
FetchContent_MakeAvailable(spdlog)

# yaml-cpp
FetchContent_Declare(
  yaml-cpp
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/yaml-cpp-yaml-cpp-0.9.0.tar.gz
)
set(BUILD_SHARED_LIBS ON)
set(YAML_BUILD_SHARED_LIBS ON)
set(YAML_CPP_BUILD_TESTS OFF)
set(YAML_CPP_BUILD_TOOLS OFF)
FetchContent_MakeAvailable(yaml-cpp)

# nlohmann_json
FetchContent_Declare(
  nlohmann_json
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/json-3.12.0.tar.gz
)
set(JSON_BuildTests OFF)
FetchContent_MakeAvailable(nlohmann_json)

# cpp-httplib
FetchContent_Declare(
  cpp-httplib
  URL ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tarballs/cpp-httplib-0.34.0.tar.gz
)
set(HTTPLIB_REQUIRE_OPENSSL OFF)
set(HTTPLIB_TEST OFF)
FetchContent_MakeAvailable(cpp-httplib)

# --- Main Project ---
set(BUILD_SHARED_LIBS OFF)

include(CTest)
enable_testing()

# --- Clang-Tidy Integration ---
option(ENABLE_CLANG_TIDY "Enable static analysis with clang-tidy" OFF)

if(ENABLE_CLANG_TIDY)
  # Prefer tools/bin/clang-tidy if it exists
  find_program(CLANG_TIDY NAMES clang-tidy 
               PATHS ${CMAKE_SOURCE_DIR}/tools/bin
               NO_DEFAULT_PATH)
  
  # Fallback to system search if not found in tools
  if(NOT CLANG_TIDY)
    find_program(CLANG_TIDY NAMES clang-tidy)
  endif()

  if(CLANG_TIDY)
    message(STATUS "Found clang-tidy: ${CLANG_TIDY}")
    # Run clang-tidy on all targets created after this
    set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY}")
  else()
    message(WARNING "clang-tidy not found, but ENABLE_CLANG_TIDY is ON")
  endif()
endif()

add_subdirectory(src/integrated_demo)

# --- Tools Integration ---
# Prefer tools/bin/clang-format if it exists
find_program(CLANG_FORMAT NAMES clang-format 
             PATHS ${CMAKE_SOURCE_DIR}/tools/bin
             NO_DEFAULT_PATH)

# Fallback to system search if not found in tools
if(NOT CLANG_FORMAT)
  find_program(CLANG_FORMAT NAMES clang-format)
endif()

if(CLANG_FORMAT)
  add_custom_target(
    format
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/format_project.sh --format --binary "${CLANG_FORMAT}"
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-format on source files..."
  )
  add_custom_target(
    check-format
    COMMAND ${CMAKE_SOURCE_DIR}/scripts/format_project.sh --check --binary "${CLANG_FORMAT}"
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Checking code format..."
  )
else()
  message(WARNING "clang-format not found. Format targets will not be available.")
endif()

# --- Sanitizer Targets ---

find_package(Threads REQUIRED)

# AddressSanitizer (ASan)
add_executable(asan_target src/sanitizers/asan/asan_test.cpp)
target_compile_options(asan_target PRIVATE -fsanitize=address -fno-omit-frame-pointer -g -O0)
target_link_options(asan_target PRIVATE -fsanitize=address)

# UndefinedBehaviorSanitizer (UBSan)
add_executable(ubsan_target src/sanitizers/ubsan/ubsan_test.cpp)
target_compile_options(ubsan_target PRIVATE -fsanitize=undefined -g -O1)
target_link_options(ubsan_target PRIVATE -fsanitize=undefined)

# ThreadSanitizer (TSan)
set(tsan_runtime_ok OFF)
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=libtsan_preinit.o
    RESULT_VARIABLE tsan_preinit_query_result
    OUTPUT_VARIABLE tsan_preinit_obj
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(tsan_preinit_query_result EQUAL 0 AND NOT tsan_preinit_obj STREQUAL "" AND NOT tsan_preinit_obj STREQUAL "libtsan_preinit.o")
    set(tsan_runtime_ok ON)
  endif()
endif()

if(tsan_runtime_ok)
  add_executable(tsan_target src/sanitizers/tsan/tsan_test.cpp)
  target_compile_options(tsan_target PRIVATE -fsanitize=thread -g -O1)
  target_link_options(tsan_target PRIVATE -fsanitize=thread)
  target_link_libraries(tsan_target PRIVATE Threads::Threads)
else()
  message(WARNING "TSan runtime not found for compiler '${CMAKE_CXX_COMPILER}'. Skipping tsan_target.")
endif()

# --- Performance Target ---

# Perf Demo Target (Optimized for profiling)
add_executable(perf_target src/performance/perf_demo.cpp)
target_compile_options(perf_target PRIVATE -g -O2 -fno-omit-frame-pointer)
target_link_options(perf_target PRIVATE -g -O2)

