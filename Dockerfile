# Docker image with a build toolchain and environment variables set to use
# the wasix-sdk sysroot.

FROM ubuntu:22.04

ENV LLVM_VERSION 16

# Install build toolchain including clang, ld, make, autotools, ninja, and cmake
RUN apt-get update && \
    # Temporarily install to setup apt repositories
    apt-get install -y curl gnupg && \
\
    curl -sS https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/llvm.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/llvm.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" >> /etc/apt/sources.list.d/llvm.list && \
    echo "deb-src [signed-by=/etc/apt/trusted.gpg.d/llvm.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main" >> /etc/apt/sources.list.d/llvm.list && \
\
    apt-get update && \
    apt-get install -y clang-${LLVM_VERSION} lld-${LLVM_VERSION} cmake ninja-build make autoconf autogen automake libtool && \
    apt-get remove -y curl gnupg && \
    rm -rf /var/lib/apt/lists/*

COPY wasix-sysroot /wasix-sysroot

ADD wasix-sdk.cmake /usr/share/cmake/wasix-sdk.cmake
ENV CMAKE_TOOLCHAIN_FILE /usr/share/cmake/wasix-sdk.cmake
ADD WASIX.cmake /usr/share/cmake/Modules/Platform/WASI.cmake

ENV CC clang-${LLVM_VERSION}
ENV CXX clang++-${LLVM_VERSION}
ENV LD wasm-ld-${LLVM_VERSION}
ENV AR llvm-ar-${LLVM_VERSION}
ENV RANLIB llvm-ranlib-${LLVM_VERSION}
ENV NM llvm-nm-${LLVM_VERSION}

ENV CFLAGS "--target=wasm32-wasmer-wasi --sysroot=/wasix-sysroot -pthread -mthread-model posix -ftls-model=local-exec -fno-trapping-math -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS"
ENV CXXFLAGS $CFLAGS -fno-exceptions
ENV LDFLAGS --target=wasm32-wasmer-wasi --sysroot=/wasix-sysroot -lwasi-emulated-mman -lwasi-emulated-process-clocks -lwasi-emulated-getpid -Wl,--shared-memory -Wl,--max-memory=4294967296 -Wl,--import-memory -Wl,--export-dynamic -Wl,--export=__heap_base -Wl,--export=__stack_pointer -Wl,--export=__data_end -Wl,--export=__wasm_init_tls -Wl,--export=__wasm_signal -Wl,--export=__tls_size -Wl,--export=__tls_align -Wl,--export=__tls_base
