FROM gcc:latest
RUN apt update
RUN apt install -y build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo libisl-dev
RUN apt install -y wget

# build the cross compiler
WORKDIR /build
# download src
RUN wget https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.gz
RUN wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.gz
RUN tar -xzf binutils-2.43.tar.gz
RUN tar -xzf gcc-14.2.0.tar.gz
RUN rm binutils-2.43.tar.gz gcc-14.2.0.tar.gz
# build setup
ENV PREFIX="/cross"
ENV TARGET=aarch64-none-elf
ENV PATH="$PREFIX/bin:$PATH"
RUN mkdir -p $PREFIX
# build binutils
RUN mkdir -p binutils
WORKDIR /build/binutils
RUN /build/binutils-2.43/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
RUN make
RUN make install
# build gcc
RUN mkdir -p /build/gcc
WORKDIR /build/gcc
RUN /build/gcc-14.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
RUN make all-gcc
RUN make all-target-libgcc
RUN make all-target-libstdc++-v3
RUN make install-gcc
RUN make install-target-libgcc
RUN make install-target-libstdc++-v3

# finalize
WORKDIR /
RUN rm -rf build
ENV CC="$TARGET-gcc"
ENV CPP="$TARGET-g++"
