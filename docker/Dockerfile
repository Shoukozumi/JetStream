ARG GCC_VERSION=16

FROM gcc:${GCC_VERSION}-trixie AS toolchain

ARG LLVM_VERSION=23
ARG VCPKG_COMMIT=5d4a3dc90c0b3773f3bac81bf41297b54328f471
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git gnupg \
    cmake ninja-build pkg-config ccache \
    zip unzip tar xz-utils \
    autoconf automake libtool bison flex \
    gdb strace linux-perf valgrind \
    python3 sudo less vim-tiny \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
    | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/trixie/ llvm-toolchain-trixie-${LLVM_VERSION} main" \
    > /etc/apt/sources.list.d/llvm.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    clang-${LLVM_VERSION} clangd-${LLVM_VERSION} clang-tidy-${LLVM_VERSION} \
    clang-format-${LLVM_VERSION} lld-${LLVM_VERSION} lldb-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} libclang-rt-${LLVM_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/* \
    && for tool in clang clang++ clangd clang-tidy clang-format ld.lld lldb \
    llvm-symbolizer llvm-profdata llvm-cov; do \
    ln -sf /usr/bin/${tool}-${LLVM_VERSION} /usr/local/bin/${tool}; \
    done

ENV VCPKG_ROOT=/opt/vcpkg \
    VCPKG_DISABLE_METRICS=1 \
    VCPKG_DEFAULT_BINARY_CACHE=/var/cache/vcpkg/archives \
    VCPKG_DOWNLOADS=/var/cache/vcpkg/downloads \
    CCACHE_DIR=/home/${USERNAME}/.cache/ccache \
    CC=gcc \
    CXX=g++ \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs
RUN mkdir -p /var/cache/vcpkg/archives /var/cache/vcpkg/downloads \
    && git clone https://github.com/microsoft/vcpkg.git "${VCPKG_ROOT}" \
    && git -C "${VCPKG_ROOT}" checkout --quiet "${VCPKG_COMMIT}" \
    && "${VCPKG_ROOT}/bootstrap-vcpkg.sh" -disableMetrics \
    && ln -s "${VCPKG_ROOT}/vcpkg" /usr/local/bin/vcpkg

RUN groupadd --gid "${GID}" "${USERNAME}" \
    && useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && mkdir -p /var/cache/vcpkg/archives /var/cache/vcpkg/downloads \
    /home/${USERNAME}/.cache/ccache /workspace \
    && chown -R "${UID}:${GID}" "${VCPKG_ROOT}" /var/cache/vcpkg \
    /home/${USERNAME}/.cache /workspace

USER ${USERNAME}
WORKDIR /workspace
CMD ["sleep", "infinity"]

FROM toolchain AS build
USER root
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/var/cache/vcpkg \
    --mount=type=cache,target=/root/.cache/ccache \
    mkdir -p /var/cache/vcpkg/archives /var/cache/vcpkg/downloads \
    && CCACHE_DIR=/root/.cache/ccache cmake --preset gcc-release \
    && CCACHE_DIR=/root/.cache/ccache cmake --build --preset gcc-release --target tick_engine

FROM debian:trixie-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --no-create-home engine
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs
COPY --from=build /src/build/gcc-release/tick_engine /usr/local/bin/tick_engine
USER engine
ENTRYPOINT ["/usr/local/bin/tick_engine"]
