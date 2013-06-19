#!/bin/bash
set -e

PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh
TOOLCHAIN="${CWD}/toolchain/arm-2010.09"
export PATH=${TOOLCHAIN}/bin:$PATH
export LD_LIBRARY_PATH="${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/"

#arm-none-linux-gnueabi-gcc -print-search-dirs

usage(){
cat <<EOF
`basename $0`
-h    : This help message
-t    : Set target to build, available targets are ${TARGETS[@]}
-d    : Destination directory
-i    : The name of the image file ( `basename ${IMGFILE}` )
-v    : Turn on verbose output
EOF
}

while getopts “hi:t:d:v” OPTION
do
     case $OPTION in
         h)
	     HELP_OPT=1
             ;;
         i)
             IMAGEFILE_OPT=$OPTARG
             ;;
         t)
	     TARGET=$OPTARG
             ;;
	 d)
	     DESTDIR_OPT=$OPTARG
	     ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

IMGFILE=${IMAGEFILE_OPT:-${CWD}/Cubian-server-r1-arm.img}
DESTDIR=${DESTDIR_OPT:-${CWD}/mnt}
TARGETS=(\
"prepare" \
"clean" \
"apache2" \
"php5" \
"mysql" \
"nginx" \
"lighthttpd" \
"memcached")

#redis
#jre
#node
#racket
#mongodb
#varnish
#haproxy

if [ ! -z "${HELP_OPT:-}" ];then
    usage
    exit 0
fi

if ! isRoot2;then
    echo "`basename $0` must be run as root"
    exit 1
fi

if [ -z "${TARGET}" ];then
    echo "TARGET is required"
    usage
    exit 2
fi

if [ -z "${DESTDIR}" ];then
    echo "DESTDIR is required"
    exit 2
fi

mountfs(){
BYTES_PER_SECTOR=`fdisk -lu ${IMGFILE} | grep ^Units | awk '{print $9}'`
LINUX_START_SECTOR=`fdisk -lu ${IMGFILE} | grep ^${IMGFILE}1 | awk '{print $2}'`
LINUX_OFFSET=`expr ${LINUX_START_SECTOR} \* ${BYTES_PER_SECTOR}`

if [ ! -d ${DESTDIR} ];then
    mkdir -p ${DESTDIR}
fi
mount -o loop,rw,offset=${LINUX_OFFSET} ${IMGFILE} ${DESTDIR}
}

installPCRE(){
    cd ${CWD}/lib/PCRE/
    # checkout the initial version
    git checkout 4a79e0108ca0c574533c5b66dd3b9188704275ea 
    CC=arm-none-linux-gnueabi-gcc \
    AR=arm-none-linux-gnueabi-ar \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--host=arm-linux \
--prefix=/ \
--cache-file=/dev/null
    make
    make install DESTDIR=${DESTDIR}
    # checkout latest version 
    git checkout PCRE-8.32 -f
    git clean -df
    cd $PWD
}

installAPRUtil(){
    cd ${CWD}/lib/APR-util
    git checkout f37f1a32aaec3f7fa2cf811ae4c13ad86aeef252
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=/ \
--with-apr=${TOOLCHAIN}/arm-none-linux-gnueabi/apr/bin/apr-1-config \
--with-iconv=${TOOLCHAIN}/arm-none-linux-gnueabi/apr-iconv \
--with-ldap-lib=${TOOLCHAIN}/arm-none-linux-gnueabi/openldap/lib \
--with-ldap-include=${TOOLCHAIN}/arm-none-linux-gnueabi/openldap/include/ \
--with-openssl=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl \
--with-crypto=${TOOLCHAIN}/arm-none-linux-gnueabi/openssl \
--with-ldap \
--host=arm-none-linux-gnueabi
    make
    make install DESTDIR=${DESTDIR}
    git checkout APR-util-1.5.2 -f
    git clean -df
    cd $PWD
}

installAPRIconv(){
    cd ${CWD}/lib/APR-iconv
    git checkout 0269e5cb48eede0c003392588f81d7aff836b5fa
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=/ \
--with-apr=${TOOLCHAIN}/arm-none-linux-gnueabi/apr/bin/apr-1-config \
--host=arm-none-linux-gnueabi
    make
    make install DESTDIR=${DESTDIR}
    git checkout APR-iconv-1.2.1 -f
    git clean -df
    cd $PWD
}

installAPR(){
    cd ${CWD}/lib/APR
    git checkout ecb4ce0eb7d8d6b3ff31dd2c35efb0ed71133034
    CC=arm-none-linux-gnueabi-gcc \
    CXX=arm-none-linux-gnueabi-g++ \
    ./configure \
--prefix=/ \
--host=arm-none-linux-gnueabi \
ac_cv_file__dev_zero=yes \
ac_cv_func_setpgrp_void=yes \
apr_cv_process_shared_works=yes \
apr_cv_mutex_robust_shared=yes \
apr_cv_tcp_nodelay_with_cork=yes \
ac_cv_sizeof_struct_iovec=8 \
ac_cv_struct_rlimit=yes
    make
    make install DESTDIR=${DESTDIR}
    git checkout APR-1.4.6 -f
    git clean -df
    cd $PWD
}

installHttpdDependencies(){
installPCRE
installAPRUtil
installAPRIconv
installAPR
}

crossCompileHttpd(){
cd ${CWD}/lib/httpd

if promptyn "reconfigure apache2?";then
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
fi

if promptyn "compile apache2?";then
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
fi
   git checkout httpd-2.2.24 -f
   git clean -df
   cd $PWD
}

case "$TARGET" in
    "prepare")
    if [ ! -f ${IMGFILE} ];then
        echo "${IMGFILE} does not exists"
        exit 4
    fi
    mountfs
    export QEMU=`which qemu-arm-static`
    sudo cp -p ${QEMU} ${DESTDIR}${QEMU}
    sudo cp -r ${TOOLCHAIN}/arm-none-linux-gnueabi/libc/lib/* ${DESTDIR}/lib
    ;;
    "apache2")
    if promptyn "recompile apache2?";then
        crossCompileHttpd
    fi
    if promptyn "install apache2?";then
    	cd ${CWD}/lib/httpd
	make install DESTDIR=${DESTDIR}
        installHttpdDependencies
    fi
    ;;
    "clean")
    sudo rm -f ${DESTDIR}${QEMU}
    ;;
    *)
    echo "sry, ${TARGET} not implemented yet"
    ;;
esac
#echo $TARGET
#chroot ${DESTDIR} /bin/bash -x <<'EOF'
#EOF
