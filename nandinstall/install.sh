#!/bin/bash

set -e

PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

NAND="/dev/nand"
NANDA="/dev/nanda"
NANDB="/dev/nandb"
NANDC="/dev/nandc"

BOOT="/mnt/nanda"
ROOTFS="/mnt/nandb"
SWAP="/mnt/nandc"

BOOTLOADER="${CWD}/bootloader"

SWAPFILE="${SWAP}/swapfile"
NANDPART="${CWD}/sunxi-tools/nand-part"

EXCLUDE="${CWD}/exclude.txt"

promptyn () {
while true; do
  read -p "$1 " yn
  case $yn in
    [Yy]* ) return 0;;
    [Nn]* ) return 1;;
    * ) echo "Please answer yes or no.";;
  esac
done
}

umountNand() {
sync
for n in ${NAND}*;do
    if [ "${NAND}" != "$n" ];then
        if mount|grep ${n};then
            echo "umounting ${n}"
            umount $n
            sleep 1
        fi
    fi
done
}

formatNand () {
expect -c "
set timeout -1
spawn $NANDPART $NAND \"linux 4000000\" \"swap 8000000\"
expect (Y/N)
send \"y\n\"
interact
"
}

mkFS(){
mkfs.ext4 $NANDB
mkfs.ext4 $NANDC
}

mountDevice(){

if [ ! -d $BOOT ];then
    mkdir $BOOT
fi
mount $NANDA $BOOT

if [ ! -d $ROOTFS ];then
    mkdir $ROOTFS
fi
mount $NANDB $ROOTFS

if [ ! -d $SWAP ];then
    mkdir $SWAP
fi
mount $NANDC $SWAP
}

installBootloader(){
echo "install bootloader"
cd $BOOT
rm -rf *
rsync -avc $BOOTLOADER/* $BOOT
cp /boot/script.bin $BOOT
cd $PWD
}

installRootfs(){
echo "install rootfs"
rsync -avc --exclude-from=$EXCLUDE / $ROOTFS
echo "please wait"
sync
}

patchRootfs(){
cat > ${ROOTFS}/etc/fstab <<END
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
/dev/nandb	/		ext4	defaults	0	1
/dev/nandc	/mnt/nandc	ext4	defaults	0	1
/mnt/nandc/swapfile	swap	swap	defaults	0	0
END
}

installSwap(){
echo "making swapfile, it will take about 5 minutes, please be patient"
dd if=/dev/zero of=$SWAPFILE bs=1M count=1024 # 1911 at maximium
mkswap $SWAPFILE
}

if promptyn "This will completely destory your data on $NAND, Are you sure to continue?"; then
    umountNand
    formatNand
    echo "please wait for a moment"
    echo "waiting 20 seconds"
    sleep 10
    echo "waiting 10 seconds"
    sleep 5
    echo "waiting 5 seconds"
    sleep 5
    mkFS
    mountDevice
    installBootloader
    installRootfs
    installSwap
    patchRootfs
    umountNand
    echo "success! remember to remove your SD card then reboot"
    if promptyn "shutdown now?";then
        shutdown -h now
    fi
fi
