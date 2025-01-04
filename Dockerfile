ARG compiler_path="/cross"
ARG target_triplet=aarch64-none-elf
ARG core_count=8

FROM ubuntu:latest AS build
ARG compiler_path
ARG target_triplet
ARG core_count
WORKDIR /build
# RUN apk --update add build-base bison flex-dev gmp-dev mpc1-dev mpfr-dev texinfo isl-dev\
#     && apk --update add wget
RUN apt update && apt install -y \
    build-essential\
    bison\
    flex\
    libgmp3-dev\
    libmpc-dev\
    libmpfr-dev\
    texinfo\
    libisl-dev\
    wget\
    tar
# download binutils src
RUN wget https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.gz \
    && tar -xzf binutils-2.43.tar.gz \
    && rm binutils-2.43.tar.gz
# download gcc src
RUN wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.gz \
    && tar -xzf gcc-14.2.0.tar.gz \
    && rm gcc-14.2.0.tar.gz
# build setup
ENV PREFIX=$compiler_path
ENV TARGET=$target_triplet
ENV PATH="$PREFIX/bin:$PATH"
ENV CORES=$core_count
RUN mkdir -p $PREFIX
# build binutils
RUN mkdir -p binutils
WORKDIR /build/binutils
RUN /build/binutils-2.43/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror\
    && make -j $CORES\
    && make install
RUN rm -rf /build/binutils-2.43
# build gcc
RUN mkdir -p /build/gcc
WORKDIR /build/gcc
RUN /build/gcc-14.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx\
    && make -j $CORES all-gcc\
    && make -j $CORES all-target-libgcc\
    && make -j $CORES all-target-libstdc++-v3
RUN make install-gcc\
    && make install-target-libgcc\
    && make install-target-libstdc++-v3
# pack up build files
WORKDIR /build
# RUN tar -czf cross.tar.gz $compiler_path

# final stage
FROM ubuntu:latest
ARG compiler_path
ARG target_triplet
WORKDIR /install
# copy and install
COPY --from=build $compiler_path $compiler_path
RUN apt update && apt install -y tar build-essential
# cleanup
RUN rm -rf /install
# finalize
ENV PATH="$compiler_path/bin:$PATH"
ENV CC="$target_triplet-gcc"
ENV CPP="$target_triplet-g++"
