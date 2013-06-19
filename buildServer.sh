#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh

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

IMGFILE=${IMAGEFILE_OPT:-./Cubian-server-r1-arm.img}
DESTDIR=${DESTDIR_OPT:-./mnt}
TARGETS=(\
"prepare" \
"apache2" \
"php5" \
"mysql" \
"redis" \
"nginx" \
"lighthttpd" \
"varnish" \
"haproxy" \
"memcached" \
"mongodb" \
"jre" \
"node" \
"racket")

DEPENDENCIES=(\
"build-essential"
"libldap2-dev" \
"libssl-dev" \
"openssl" \
"libexpat1-dev" \
"zlib1g-dev" \
"liblua5.1-0-dev" \
"libxml2-dev" \
"re2c" \
"bison" \
"libssl-dev" \
"libpcre3-dev" \
"libbz2-dev" \
"libcurl4-openssl-dev" \
"libdb5.1-dev" \
"libjpeg8-dev" \
"libpng12-dev" \
"libxpm-dev" \
"libfreetype6-dev" \
"libmysqlclient-dev" \
"postgresql-server-dev-9.1" \
"libt1-dev" \
"libgd2-xpm-dev" \
"libgmp-dev" \
"libsasl2-dev" \
"libmhash-dev" \
"unixodbc-dev" \
"freetds-dev" \
"libpspell-dev" \
"libsnmp-dev" \
"libtidy-dev" \
"libxslt1-dev" \
"libmcrypt-dev" \
"libvpx-dev")

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

if [ ! -f ${IMGFILE} ];then
    echo "${IMGFILE} does not exists"
    exit 4
fi

#if [ $(contains "${TARGETS[@]}" "${TARGET}") == "n" ];then
#    echo "${TARGET} is not supported"
#    exit 3
#fi

BYTES_PER_SECTOR=`fdisk -lu ${IMGFILE} | grep ^Units | awk '{print $9}'`
LINUX_START_SECTOR=`fdisk -lu ${IMGFILE} | grep ^${IMGFILE}1 | awk '{print $2}'`
LINUX_OFFSET=`expr ${LINUX_START_SECTOR} \* ${BYTES_PER_SECTOR}`

if [ ! -z "${DESTDIR}" ];then
    if [ ! -d ${DESTDIR} ];then
        mkdir -p ${DESTDIR}
    else
        umount ${DESTDIR}>/dev/null 2>&1
    fi
    mount -o loop,rw,offset=${LINUX_OFFSET} ${IMGFILE} ${DESTDIR}
fi

case "$TARGET" in
    "prepare")
    export QEMU=`which qemu-arm-static`
    sudo cp -p ${QEMU} ${DESTDIR}${QEMU}
    cat >> ${DESTDIR}/etc/apt/sources.list <<END
#deb http://mirrors.sohu.com/debian/ wheezy main contrib non-free
deb-src http://http.debian.net/debian/ wheezy main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free
END
LC_ALL=C LANGUAGE=C LANG=C chroot ${DESTDIR} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${DESTDIR} apt-get -y install ${DEPENDENCIES[@]}
    ;;
    "apache2")
    echo "building apache2"
    BUILD_HOME="/home/cubie/apache2"
    if promptyn "copying files?";then
        #tar --exclude=".git" -czf - ./lib | ( cd ../${DESTDIR}/home/cubie; tar -xzvf -)
        rsync -avc --exclude '.git' ${CWD}/lib/APR* \
${CWD}/lib/PCRE \
${CWD}/lib/httpd \
${CWD}/fns.sh \
${CWD}/compileApache.sh \
${DESTDIR}${BUILD_HOME}
    fi
    chroot ${DESTDIR} /bin/bash -c "su - -c ${BUILD_HOME}/compileApache.sh"
    ;;
    "php5")
    echo "building php"
    BUILD_HOME="/home/cubie/php5"
    if promptyn "copying files?";then
        rsync -avc --exclude '.git' ${CWD}/lib/php5* \
${CWD}/fns.sh \
${CWD}/compilePHP.sh \
${DESTDIR}${BUILD_HOME}
    fi
    chroot ${DESTDIR} /bin/bash -c "su - -c ${BUILD_HOME}/compilePHP.sh"
    ;;
    *)
    echo "sry, ${TARGET} not implemented yet"
    ;;
esac
#echo $TARGET
#chroot ${DESTDIR} /bin/bash -x <<'EOF'
#EOF
