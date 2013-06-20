#!/bin/bash
set -e

PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh
TOOLCHAIN="${CWD}/toolchain/arm-2010.09"
export PATH=${TOOLCHAIN}/bin:$PATH
export LD_LIBRARY_PATH="${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/"

#arm-none-linux-gnueabi-gcc -print-search-dirs

crossCompilePCRE(){
    cd ${CWD}/lib/PCRE/
    # checkout the initial version
    git checkout 4a79e0108ca0c574533c5b66dd3b9188704275ea 
    CC=arm-none-linux-gnueabi-gcc \
    AR=arm-none-linux-gnueabi-ar \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--host=arm-linux \
--target=arm-linux \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/pcre \
--cache-file=/dev/null
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
    CC=arm-none-linux-gnueabi-gcc \
    AR=arm-none-linux-gnueabi-ar \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--host=arm-none-linux-gnueabi \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/libc/usr \
--cache-file=/dev/null
    make
    #pushd include && ln -fs curses.h ncurses.h && popd
    make install
    # checkout latest version 
    git checkout ncurses-5.9 -f
    git clean -df
    cd $PWD
}

crossCompileOpenSSL(){
    cd ${CWD}/lib/openssl
    git checkout 357a79461dbe75e08d9dc4137767d176995be8b9
    export cross=arm-none-linux-gnueabi-
    ./Configure dist \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl
#--openssldir=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl

    make CC="${cross}gcc" \
AR="${cross}ar r" \
RANLIB="${cross}ranlib"
    make install
    git checkout openssl-1.0.1e -f
    git clean -df
    cd $PWD
}

crossCompileZlib(){
    cd ${CWD}/lib/zlib
    git checkout 44321df669487c1a8bde87939947baf06463adbc
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/zlib
    make
    make install
    git checkout zlib-1.2.8 -f
    git clean -df
    cd $PWD
}

crossCompileAPR(){
    cd ${CWD}/lib/APR
    git checkout ecb4ce0eb7d8d6b3ff31dd2c35efb0ed71133034
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/apr \
--host=arm-none-linux-gnueabi \
ac_cv_file__dev_zero=yes \
ac_cv_func_setpgrp_void=yes \
apr_cv_process_shared_works=yes \
apr_cv_mutex_robust_shared=yes \
apr_cv_tcp_nodelay_with_cork=yes \
ac_cv_sizeof_struct_iovec=8 \
ac_cv_struct_rlimit=yes
    make
    make install
    git checkout APR-1.4.6 -f
    git clean -df
    cd $PWD
}

crossCompileAPRIconv(){
    cd ${CWD}/lib/APR-iconv
    git checkout 0269e5cb48eede0c003392588f81d7aff836b5fa
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/apr-iconv \
--with-apr=${TOOLCHAIN}/arm-none-linux-gnueabi/apr/bin/apr-1-config \
--host=arm-none-linux-gnueabi
    make
    make install
    git checkout APR-iconv-1.2.1 -f
    git clean -df
    cd $PWD
}

crossCompileLDAP() {
    cd ${CWD}/lib/openldap
    git checkout 3c25a9eb5e7a1d443eadfa7a0c19e52b09f5f5ce
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/openldap \
--without-yielding-select \
--disable-slapd \
--host=arm-none-linux-gnueabi
    make

    sudo mv /usr/bin/strip /usr/bin/strip.backup
    sudo ln -s ${TOOLCHAIN}/bin/arm-none-linux-gnueabi-strip /usr/bin/strip
    make install

    sudo mv /usr/bin/strip.backup /usr/bin/strip

    git checkout openldap-2.4.35 -f
    git clean -df
    cd $PWD
}

crossCompileAPRUtil(){
    cd ${CWD}/lib/APR-util
    git checkout f37f1a32aaec3f7fa2cf811ae4c13ad86aeef252
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=${TOOLCHAIN}/arm-none-linux-gnueabi/apr-util \
--with-apr=${TOOLCHAIN}/arm-none-linux-gnueabi/apr/bin/apr-1-config \
--with-iconv=${TOOLCHAIN}/arm-none-linux-gnueabi/apr-iconv \
--with-ldap-lib=${TOOLCHAIN}/arm-none-linux-gnueabi/openldap/lib \
--with-ldap-include=${TOOLCHAIN}/arm-none-linux-gnueabi/openldap/include/ \
--with-openssl=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl \
--with-crypto=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl \
--with-ldap \
--host=arm-none-linux-gnueabi
    make
    make install
    git checkout APR-util-1.5.2 -f
    git clean -df
    cd $PWD
}

testCompileHttpd(){
cd ${CWD}/lib/httpd

git checkout 3ee23b629365178d8cfd3b28d4b2be68312ca252
CC=arm-none-linux-gnueabi-gcc \
AR=arm-none-linux-gnueabi-ar \
LD=arm-none-linux-gnueabi-ld \
CXX=arm-none-linux-gnueabi-g++ \
./configure \
ap_cv_void_ptr_lt_long=no \
--with-pcre=${TOOLCHAIN}/arm-none-linux-gnueabi/pcre \
--with-apr=${TOOLCHAIN}/arm-none-linux-gnueabi/apr/bin/apr-1-config \
--with-apr-util=${TOOLCHAIN}/arm-none-linux-gnueabi/apr-util/bin/apu-1-config \
--with-z=${TOOLCHAIN}/arm-none-linux-gnueabi/zlib \
--with-ssl=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl \
--with-mpm=prefork \
--with-port=8080 \
--host=arm-none-linux-gnueabi \
--enable-modules=all \
--enable-mods-shared=all \
--enable-ssl \
--enable-rewrite \
--enable-so \
--enable-static-ab \
--enable-static-checkgid \
--enable-static-htdbm \
--enable-static-htdigest \
--enable-static-htpasswd \
--enable-static-logresolve \
--enable-static-rotatelogs \
--enable-vhost-alias \
--enable-v4-mapped

ldlinux="/lib/ld-linux.so.3"
libgcc="/lib/libgcc_s.so.1"
libc="/lib/libc.so.6"

if [[ ! -f "$ldlinux" ]];then
    sudo ln -s ${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/ld-linux.so.3 $ldlinux
fi
if [[ ! -f "$libgcc" ]];then
    sudo ln -s ${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/libgcc_s.so.1 $libgcc
fi
if [[ ! -f "$libc" ]];then
    sudo ln -s ${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/libc.so.6 $libc
fi
   make
   sudo rm $ldlinux
   sudo rm $libgcc
   sudo rm $libc

   git checkout httpd-2.2.24 -f
   git clean -df
   cd $PWD
}

# DO NOT call this function, the toolchain is already prepared
# if you clone this repo from github, just for history purpose
prepareToolchain(){
crossCompilePCRE
crossCompileNcurses
crossCompileOpenSSL
crossCompileZlib
crossCompileAPR
crossCompileAPRIconv
crossCompileLDAP
crossCompileAPRUtil
testCompileHttpd
}

