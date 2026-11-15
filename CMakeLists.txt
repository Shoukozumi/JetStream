cmake_minimum_required(VERSION 3.25)
project(tick_engine VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(TICK_SANITIZER "" CACHE STRING "Sanitizers to enable, e.g. address;undefined or thread")
option(TICK_WARNINGS_AS_ERRORS "Treat warnings as errors" ON)
option(TICK_STATIC_RUNTIME "Statically link libstdc++ and libgcc (release images)" OFF)

# ---- Shared compile settings: link this into every target of ours ----
add_library(tick_options INTERFACE)
target_compile_options(tick_options INTERFACE
  -Wall -Wextra -Wshadow -Wnon-virtual-dtor
  $<$<BOOL:${TICK_WARNINGS_AS_ERRORS}>:-Werror>)

if(TICK_SANITIZER)
  list(JOIN TICK_SANITIZER "," _tick_san)
  target_compile_options(tick_options INTERFACE
    -fsanitize=${_tick_san} -fno-omit-frame-pointer -fno-sanitize-recover=all)
  target_link_options(tick_options INTERFACE -fsanitize=${_tick_san})
endif()

if(TICK_STATIC_RUNTIME)
  target_link_options(tick_options INTERFACE -static-libstdc++ -static-libgcc)
endif()

# ---- Dependencies (all from vcpkg.json) ----
find_package(boost_asio CONFIG REQUIRED)
find_package(boost_beast CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
if(OPENSSL_VERSION VERSION_LESS 3.1)
  message(FATAL_ERROR "OpenSSL ${OPENSSL_VERSION} found; 3.1 or newer is required (3.0.x is slow)")
endif()
find_package(simdjson CONFIG REQUIRED)
find_package(quill CONFIG REQUIRED)
find_package(opentelemetry-cpp CONFIG REQUIRED)
find_package(hdr_histogram CONFIG REQUIRED)
include(cmake/ClickHouseCpp.cmake)

set(TICK_HDR_TARGET
  $<IF:$<TARGET_EXISTS:hdr_histogram::hdr_histogram>,hdr_histogram::hdr_histogram,hdr_histogram::hdr_histogram_static>)

# ---- Engine ----
add_executable(tick_engine src/main.cpp)
target_link_libraries(tick_engine PRIVATE
  tick_options
  Boost::asio Boost::beast
  OpenSSL::SSL OpenSSL::Crypto
  simdjson::simdjson
  quill::quill
  opentelemetry-cpp::api opentelemetry-cpp::sdk opentelemetry-cpp::metrics
  opentelemetry-cpp::prometheus_exporter
  ${TICK_HDR_TARGET}
  clickhouse::cpp)

