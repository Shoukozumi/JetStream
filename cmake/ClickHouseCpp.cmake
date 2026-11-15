find_package(absl CONFIG REQUIRED)
find_package(lz4 CONFIG REQUIRED)
find_package(zstd CONFIG REQUIRED)
find_package(cityhash CONFIG REQUIRED)

find_path(CLICKHOUSE_CPP_INCLUDE_DIR clickhouse/client.h REQUIRED)
find_library(CLICKHOUSE_CPP_LIBRARY NAMES clickhouse-cpp-lib REQUIRED)

add_library(clickhouse::cpp UNKNOWN IMPORTED)
set_target_properties(clickhouse::cpp PROPERTIES
  IMPORTED_LOCATION "${CLICKHOUSE_CPP_LIBRARY}"
  INTERFACE_INCLUDE_DIRECTORIES "${CLICKHOUSE_CPP_INCLUDE_DIR}")
target_link_libraries(clickhouse::cpp INTERFACE
  absl::int128 cityhash lz4::lz4 zstd::libzstd)
