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
