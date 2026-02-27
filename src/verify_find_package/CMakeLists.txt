cmake_minimum_required(VERSION 3.20)

project(verify_find_package LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(absl CONFIG REQUIRED)
find_package(Catch2 CONFIG REQUIRED)
find_package(httplib CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)

include(CTest)
enable_testing()

add_executable(verify_link src/verify_link.cpp)
target_link_libraries(verify_link PRIVATE
  absl::strings
  absl::time
  nlohmann_json::nlohmann_json
  spdlog::spdlog
  yaml-cpp::yaml-cpp
  httplib::httplib
)

add_executable(verify_catch2)
target_sources(verify_catch2 PRIVATE src/verify_catch2.cpp)
if(TARGET Catch2::Catch2)
  target_sources(verify_catch2 PRIVATE src/catch2_main.cpp)
  target_link_libraries(verify_catch2 PRIVATE Catch2::Catch2)
else()
  target_link_libraries(verify_catch2 PRIVATE Catch2::Catch2WithMain)
endif()

add_test(NAME verify_catch2 COMMAND verify_catch2)
