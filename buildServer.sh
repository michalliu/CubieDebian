#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

usage(){
cat <<EOF
`basename $0`
-h    : This help message
-d    : Destination directory
-i    : The name of the image file ( `basename ${IMGFILE}` )
-v    : Turn on verbose output
EOF
}

while getopts “hi:d:v” OPTION
do
     case $OPTION in
         h)
	     HELP_OPT=1
             ;;
         i)
             IMAGEFILE_OPT=$OPTARG
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
IMGFILE=${IMAGEFILE_OPT:-./Cubian-base-r1-arm.img}
DESTDIR=${DESTDIR_OPT:-./mnt}

if [ ! -z "${HELP_OPT:-}" ];then
    usage
    exit
fi

if [[ ${EUID} != 0 && ${UID} != 0 ]];then
    echo "`basename $0` must be run as root"
    exit -1
fi

if [ ! -f ${IMGFILE} ];then
    echo "${IMGFILE} does not exists"
    exit 1
fi

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

chroot ${DESTDIR} /bin/bash -x <<'EOF'
ls /home
sleep 2
ls /home/cubie
EOF
