cmake_minimum_required(VERSION 3.20)

project(integrated_demo VERSION 0.1.0 LANGUAGES CXX)


if(NOT TARGET absl::strings)
  find_package(absl CONFIG REQUIRED)
endif()
if(NOT TARGET Catch2::Catch2)
  find_package(Catch2 CONFIG REQUIRED)
endif()
if(NOT TARGET httplib::httplib)
  find_package(httplib CONFIG REQUIRED)
endif()
if(NOT TARGET nlohmann_json::nlohmann_json)
  find_package(nlohmann_json CONFIG REQUIRED)
endif()
if(NOT TARGET spdlog::spdlog)
  find_package(spdlog CONFIG REQUIRED)
endif()
if(NOT TARGET yaml-cpp::yaml-cpp)
  find_package(yaml-cpp CONFIG REQUIRED)
endif()

add_library(integrated_demo_core)
target_sources(integrated_demo_core
  PRIVATE
    src/AppConfig.cpp
    src/Logging.cpp
    src/RestServer.cpp
)
target_include_directories(integrated_demo_core
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_link_libraries(integrated_demo_core
  PUBLIC
    absl::strings
    absl::time
    absl::str_format
    nlohmann_json::nlohmann_json
    spdlog::spdlog
    yaml-cpp::yaml-cpp
    httplib::httplib
)

# Link against 'anl' (Asynchronous Name Lookups) if needed on Linux/CentOS
if(UNIX AND NOT APPLE)
  find_library(LIB_ANL anl)
  if(LIB_ANL)
    target_link_libraries(integrated_demo_core PUBLIC ${LIB_ANL})
  endif()
endif()

add_executable(integrated_demo_server src/server_main.cpp)
target_link_libraries(integrated_demo_server PRIVATE integrated_demo_core)

add_executable(integrated_demo_client src/client_main.cpp)
target_link_libraries(integrated_demo_client PRIVATE integrated_demo_core)

add_executable(integrated_demo_tests)
target_sources(integrated_demo_tests PRIVATE tests/test_main.cpp)
if(TARGET Catch2::Catch2)
  target_sources(integrated_demo_tests PRIVATE tests/catch2_main.cpp)
  target_link_libraries(integrated_demo_tests PRIVATE integrated_demo_core Catch2::Catch2)
else()
  target_link_libraries(integrated_demo_tests PRIVATE integrated_demo_core Catch2::Catch2WithMain)
endif()

include(CTest)
enable_testing()
add_test(NAME integrated_demo_tests COMMAND integrated_demo_tests)

foreach(tgt integrated_demo_server integrated_demo_client integrated_demo_tests)
  set_target_properties(${tgt} PROPERTIES
    INSTALL_RPATH "\$ORIGIN/../lib"
    BUILD_RPATH "\$ORIGIN/../lib"
  )
endforeach()

install(TARGETS integrated_demo_server integrated_demo_client integrated_demo_tests
  RUNTIME DESTINATION bin
)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/config/
  DESTINATION share/integrated_demo/config
)
