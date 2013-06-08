#!/bin/bash
set -e

PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh
TOOLCHAIN="${CWD}/toolchain/arm-2010.09"
export PATH=${TOOLCHAIN}/bin:$PATH

#arm-none-linux-gnueabi-gcc -print-search-dirs

crossCompilePCRE(){
    cd ${CWD}/lib/PCRE/
    # checkout the initial version
    git checkout 4a79e0108ca0c574533c5b66dd3b9188704275ea 
    CC=arm-none-linux-gnueabi-gcc AR=arm-none-linux-gnueabi-ar CXX=arm-none-linux-gnueabi-g++ ./configure --host=arm-linux --target=arm-linux --prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/libc/usr --cache-file=/dev/null
    make
    make install
    # checkout latest version 
    git checkout PCRE-8.32 -f
    git clean -df
    cd $PWD
}

crossCompileNcurses(){
    cd ${CWD}/lib/ncurses
    # checkout the initial version
    git checkout 5c8c4639c74c95041d7e57bf97a38e40d62aa9f6 
    CC=arm-none-linux-gnueabi-gcc AR=arm-none-linux-gnueabi-ar CXX=arm-none-linux-gnueabi-g++ ./configure --host=arm-linux --target=arm-linux --prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/libc/usr --cache-file=/dev/null
    make
    make install
    # checkout latest version 
    git checkout ncurses-5.9 -f
    git clean -df
    cd $PWD
}

crossCompileAPR(){
    cd ${CWD}/lib/APR
    git checkout ecb4ce0eb7d8d6b3ff31dd2c35efb0ed71133034
    CC=arm-none-linux-gnueabi-gcc \
    AR=arm-none-linux-gnueabi-ar \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/apr \
--host=arm-linux-gnueabi \
--target=arm-linux \
--cache-file=/dev/null
    make
    #git checkout APR-1.4.6 -f
    #git clean -df
    #cd $PWD
}
crossCompileAPR
exit
# DO NOT call this function, the toolchain is already prepared
# if you clone this repo from github, just for history purpose
prepareToolchain(){
    crossCompilePCRE
    crossCompileNcurses
}
