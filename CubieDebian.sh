#!/bin/bash

#################
# CONFIGURATION #
#################
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)
CPU_CORES=$(grep -m1 cpu\ cores /proc/cpuinfo | cut -d : -f 2)
A10="a10"
A20="a20"

source ${CWD}/fns.sh

UBOOT_REPO="${CWD}/u-boot-sunxi"
UBOOT_REPO_A10_MMC="${CWD}/u-boot-sunxi-a10-mmc"
UBOOT_REPO_A10_NAND="${CWD}/u-boot-sunxi-a10-nand"

UBOOT_REPO_A20_MMC="${CWD}/u-boot-sunxi-a20-mmc"
UBOOT_REPO_A20_MMC_FIXED_MACHID="${CWD}/u-boot-sunxi-a20-mmc-fixed-machid"
UBOOT_REPO_A20_NAND="${CWD}/u-boot-sunxi-a20-nand"
UBOOT_REPO_A20_NAND_FIXED_MACHID="${CWD}/u-boot-sunxi-a20-nand-fixed-machid"

UBOOT_A10_MMC="stage/a10-mmc"
UBOOT_A10_NAND="stage/a10-nand"

UBOOT_A20_MMC="stage/a20-mmc"
UBOOT_A20_MMC_FIXED_MACHID="stage/a20-mmc-fixed-machid"
UBOOT_A20_NAND="stage/a20-nand"
UBOOT_A20_NAND_FIXED_MACHID="stage/a20-nand-fixed-machid"

LINUX_REPO="${CWD}/linux-sunxi"
LINUX_REPO_A10="${CWD}/linux-sunxi-a10"
LINUX_REPO_A20_3_4="${CWD}/linux-sunxi-a20-3.4"
LINUX_REPO_A20_3_3="${CWD}/linux-sunxi-a20-3.3"

LINUX_PACKAGES="${CWD}/packages"
LINUX_HEADER_A10_3_3="${LINUX_PACKAGES}/linux-header-3.3.0"
LINUX_HEADER_A20_3_4="${LINUX_PACKAGES}/linux-header-3.4.43"

LINUX_A10="stage/sunxi-3.4-a10"
LINUX_A20_3_4="dev/sunxi-3.4-a20"
LINUX_A20_3_3="stage/sunxi-3.3-a20"

LINUX_CONFIG_BASE_SUN4I="${CWD}/kernel-config/config-cubian-base-sun4i"
LINUX_CONFIG_BASE_SUN7I_3_4="${CWD}/kernel-config/config-cubian-base-sun7i-3.4"
LINUX_CONFIG_BASE_SUN7I_3_3="${CWD}/kernel-config/config-cubian-base-sun7i-3.3"

FS_UPDATE_REPO="${CWD}/fsupdate"
FS_UPDATE_REPO_BASE="${CWD}/fsupdatebase"

SUNXI_TOOLS_REPO="${CWD}/sunxi-tools"
SUNXI_TOOLS_REPO_ARM_A10="${CWD}/sunxi-tools-arm-a10"
SUNXI_TOOLS_REPO_ARM_A20="${CWD}/sunxi-tools-arm-a20"

SUNXI_TOOLS_A10="master"
SUNXI_TOOLS_A20="a20/mbr411"

FS_UPDATE_BASE="base"

# This is the script verion
SCRIPT_VERSION="1.0"
RELEASE_VERSION_A10="4"
RELEASE_VERSION_A20="1"
DEVELOPMENT_CODE="argon"

FEX_SUN4I="${CWD}/sunxi-boards/sys_config/a10/cubieboard_${DEVELOPMENT_CODE}.fex"
FEX_SUN7I="${CWD}/sunxi-boards/sys_config/a20/cubieboard2_${DEVELOPMENT_CODE}.fex"

FEX2BIN="${SUNXI_TOOLS_REPO}/fex2bin"

# This will be the hostname of the cubieboard
DEB_HOSTNAME="Cubian"

# Not all packages can be install this way.
# DEB_EXTRAPACKAGES="nvi locales ntp ssh expect"
# Currently ntp module triggers an error when install
DEB_WIRELESS_TOOLS="wireless-tools wpasupplicant"
DEB_TEXT_EDITORS="nvi vim"
DEB_TEXT_UTILITIES="locales ssh expect sudo"
DEB_ADMIN_UTILITIES="inotify-tools ifplugd ntpdate rsync parted lsof psmisc dosfstools at"
DEB_CPU_UTILITIES="cpufrequtils sysfsutils"
DEB_SOUND="alsa-base alsa-utils"
DEB_EXTRAPACKAGES="${DEB_TEXT_EDITORS} ${DEB_TEXT_UTILITIES} ${DEB_WIRELESS_TOOLS} ${DEB_ADMIN_UTILITIES} ${DEB_CPU_UTILITIES} ${DEB_SOUND}" 
# Not all packages can (or should be) reconfigured this way.
DPKG_RECONFIG="locales tzdata"

# Make sure this is valid and is really your SD..
SD_PATH="/dev/sdb"

# SD Card mount point
SD_MNT_POINT="${CWD}/mnt"

# MAC will be encoded in script.bin
#MAC_ADDRESS="0DEADBEEFBAD"
MAC_ADDRESS="008010EDDF01"

# If you want to use DHCP, use the following
ETH0_MODE="dhcp"

# Rootfs Dir
ROOTFS_DIR="${CWD}/rootfs/${DEVELOPMENT_CODE}-armfs"

# Rootfs backup
ROOTFS_BACKUP="${DEVELOPMENT_CODE}.rootfs.tar.gz"

# Base system backup
BASESYS_BACKUP="${DEVELOPMENT_CODE}.basesys.tar.gz"

# Base system has package backup
BASESYS_PKG_BACKUP="${DEVELOPMENT_CODE}.basesys.pkg.tar.gz"

# Base system with basic standard config without personal stuff
BASESYS_CONFIG_BACKUP="${DEVELOPMENT_CODE}.basesys.config.tar.gz"

# Base system with basic standard config without personal stuff
BASESYS_FINAL_BACKUP="${DEVELOPMENT_CODE}.basesys.final.tar.gz"

# Accounts
DEFAULT_USERNAME="cubie"
DEFAULT_PASSWD="cubie"

# If you want a static IP, use the following
#ETH0_MODE="static"
#ETH0_IP="192.168.0.100"
#ETH0_MASK="255.255.255.0"
#ETH0_GW="192.168.0.1"
#DNS1="8.8.8.8"
#DNS2="8.8.4.4"
#DNS_SEARCH="localhost.com"

########################
# END OF CONFIGURATION #
########################
set -e

TOOLCHAIN="${CWD}/toolchain"
TOOLCHAIN_LINARO_REPO="${CWD}/toolchain-linaro"
LINARO_BRANCH="arm-linaro-2013.06"

export PATH=${TOOLCHAIN}/bin:$PATH
export PATH=${TOOLCHAIN_LINARO_REPO}/bin:$PATH

setupTools() {
installpackages "debootstrap" "qemu-user-static" "build-essential" "u-boot-tools" "git" "binfmt-support" "libusb-1.0-0-dev" "pkg-config" "libncurses5-dev" "debian-archive-keyring" "expect" "kpartx" "p7zip-full" "e2fsprogs" "dch" "lintian"
}

setupLinaroToolchain(){
gitOpt="--git-dir=${TOOLCHAIN_LINARO_REPO}/.git --work-tree=${TOOLCHAIN_LINARO_REPO}/"
if [ ! -d $TOOLCHAIN_LINARO_REPO ];then
    git clone $TOOLCHAIN $TOOLCHAIN_LINARO_REPO
fi
branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
if [ "$branchName" != "$LINARO_BRANCH" ]; then
    echoRed "Switch branch to ${LINARO_BRANCH}"
    git $gitOpt checkout .
    git $gitOpt clean -df
    git $gitOpt checkout ${LINARO_BRANCH}
fi
}

setupfsupdatebase(){
gitOpt="--git-dir=${FS_UPDATE_REPO_BASE}/.git --work-tree=${FS_UPDATE_REPO_BASE}/"
if [ ! -d $FS_UPDATE_REPO_BASE ];then
    git clone $FS_UPDATE_REPO $FS_UPDATE_REPO_BASE
fi
branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
if [ "$branchName" != "$FS_UPDATE_BASE" ]; then
    echoRed "Switch branch to ${FS_UPDATE_BASE}"
    git $gitOpt checkout .
    git $gitOpt clean -df
    git $gitOpt checkout ${FS_UPDATE_BASE}
fi
git $gitOpt pull
}

initRepo() {
git submodule init
git submodule update
}

buildUBoot() {
if [ "$1" == "$UBOOT_REPO_A20_MMC" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 cubieboard2 CROSS_COMPILE=$CROSS_COMPILER
elif [ "$1" == "$UBOOT_REPO_A20_MMC_FIXED_MACHID" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 cubieboard2 CROSS_COMPILE=$CROSS_COMPILER
elif [ "$1" == "$UBOOT_REPO_A20_NAND" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 sun7i CROSS_COMPILE=$CROSS_COMPILER
elif [ "$1" == "$UBOOT_REPO_A20_NAND_FIXED_MACHID" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 sun7i CROSS_COMPILE=$CROSS_COMPILER
elif [ "$1" == "$UBOOT_REPO_A10_MMC" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 cubieboard CROSS_COMPILE=$CROSS_COMPILER
elif [ "$1" == "$UBOOT_REPO_A10_NAND" ];then
CROSS_COMPILER=arm-none-linux-gnueabi-
make -C $1 distclean CROSS_COMPILE=$CROSS_COMPILER
make -C $1 cubieboard CROSS_COMPILE=$CROSS_COMPILER
fi
}

buildTools() {
make -C ${SUNXI_TOOLS_REPO} clean
make -C ${SUNXI_TOOLS_REPO} all
}

prepareEnv() {
# install qemu
if [ ! -f ${ROOTFS_DIR}/usr/bin/qemu-arm-static ];then
    cp `which qemu-arm-static` ${ROOTFS_DIR}/usr/bin
fi
if [ ! -f ${ROOTFS_DIR}/etc/resolv.conf ];then
    cp /etc/resolv.conf ${ROOTFS_DIR}/etc/
fi
}

downloadSys(){
if [ -d ${ROOTFS_DIR} ];then
    rm -rf ${ROOTFS_DIR}
fi
mkdir --parents ${ROOTFS_DIR}
debootstrap --foreign --verbose --arch armhf wheezy ${ROOTFS_DIR}/ http://http.debian.net/debian/
}

installBaseSys(){
prepareEnv
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} /debootstrap/debootstrap --second-stage
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg --configure -a
cp /etc/resolv.conf ${ROOTFS_DIR}/etc/
cat > ${ROOTFS_DIR}/etc/apt/sources.list <<END
deb http://http.debian.net/debian/ wheezy main contrib non-free
deb http://security.debian.org/ wheezy/updates main contrib non-free
END
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get upgrade
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get clean
}

installPackages(){
prepareEnv
# install extra modules
if [ -n "${DEB_EXTRAPACKAGES}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get -y install ${DEB_EXTRAPACKAGES}
fi
}

installBootscr() {
cat > ${ROOTFS_DIR}/boot/boot.cmd <<END
setenv bootargs console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x800p60 root=/dev/mmcblk0p1 rootwait panic=10
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
END
mkimage -C none -A arm -T script -d ${ROOTFS_DIR}/boot/boot.cmd ${ROOTFS_DIR}/boot/boot.scr
}

installFex(){
echoRed "using fex $1"
scriptSrc="${ROOTFS_DIR}/boot/script.fex"
scriptBinary="${ROOTFS_DIR}/boot/script.bin"
cp $1 $scriptSrc
$FEX2BIN $scriptSrc $scriptBinary
}

installKernel() {
cp ${CURRENT_KERNEL}/arch/arm/boot/uImage ${ROOTFS_DIR}/boot
make -C ${CURRENT_KERNEL} INSTALL_MOD_PATH=${ROOTFS_DIR} ARCH=arm modules_install
if [ "$CURRENT_KERNEL" = "$LINUX_REPO_A10" ];then
kernelVersion="3.4.43+"
elif [ "$CURRENT_KERNEL" = "$LINUX_REPO_A20_3_3" ];then
kernelVersion="3.3.0+"
elif [ "$CURRENT_KERNEL" = "$LINUX_REPO_A20_3_4" ];then
kernelVersion="3.4.43.sun7i+"
fi
kernelSourceLocation="/usr/src/linux-headers-${kernelVersion}"
kernelSourcePointer1="${ROOTFS_DIR}/lib/modules/${kernelVersion}/build"
kernelSourcePointer2="${ROOTFS_DIR}/lib/modules/${kernelVersion}/source"
echo "create kernel headers link"
rm $kernelSourcePointer1
rm $kernelSourcePointer2
ln -sf "$kernelSourceLocation" "$kernelSourcePointer1" 
ln -sf "$kernelSourceLocation" "$kernelSourcePointer2"
}

configNetwork() {
cat > ${ROOTFS_DIR}/etc/network/interfaces <<END
# the loopback interface
auto lo
iface lo inet loopback

#
auto eth0
allow-hotplug eth0
iface eth0 inet ${ETH0_MODE}
END

if [ "${ETH0_MODE}" != "dhcp" ]; then 
cat >> ${ROOTFS_DIR}/etc/network/interfaces <<END
address ${ETH0_IP}
netmask ${ETH0_MASK}
gateway ${ETH0_GW}
END
cat > ${ROOTFS_DIR}/etc/resolv.conf <<END
search ${DNS_SEARCH}
nameserver ${DNS1}
nameserver ${DNS2}
END
fi
}

configSys(){
prepareEnv

# prompt to config local and timezone
if promptyn "Configure locale and timezone data?"; then
    if [ -n "${DPKG_RECONFIG}" ]; then
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg-reconfigure ${DPKG_RECONFIG}
    fi
fi
}

restoreFile() {
bakfile="$1.bak"
if [ -f $bakfile ];then
    cp $bakfile $1
else
    echo "[W] can't restore, backup file $bakfile not exists"
fi
}

backupFile() {
bakfile="$1.bak"
if [ ! -f $bakfile ];then
    cp $1 $bakfile
fi
}

installPersonalStuff(){
NETWORK_CFG=`${CWD}/utilities/network_cfg.sh`
cat >> ${ROOTFS_DIR}/etc/network/interfaces <<END

#
${NETWORK_CFG}
END
}

applyPatch(){
patch "${ROOTFS_DIR}/${2:${#1}:-6}" < "$2"
}

finalConfig(){
prepareEnv

echo ${DEB_HOSTNAME} > ${ROOTFS_DIR}/etc/hostname

cat >> ${ROOTFS_DIR}/etc/hosts <<END
127.0.0.1 ${DEB_HOSTNAME}
END

# config user accounts
cat > ${ROOTFS_DIR}/tmp/initsys.sh <<END
#!/bin/bash
# add default user
groupadd gpio
if [ -z "\$(getent passwd ${DEFAULT_USERNAME})" ];then
    useradd -m -s /bin/bash -G gpio,audio,sudo ${DEFAULT_USERNAME}
fi

# set user
echo "${DEFAULT_USERNAME}:${DEFAULT_PASSWD}"|chpasswd

# disable root user
passwd -l root
END
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} chmod +x /tmp/initsys.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} /tmp/initsys.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} rm /tmp/initsys.sh

# copy new files common
setupfsupdatebase
rsync --exclude *.patch -av ${FS_UPDATE_REPO_BASE}/common/* ${ROOTFS_DIR}

# patch common files
find ${FS_UPDATE_REPO_BASE}/common/ -type f -name "*.patch" | while read patch; do applyPatch "${FS_UPDATE_REPO_BASE}/common/" "$patch";done

# green led ctrl
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-bootled" defaults
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-blinknetworkled" defaults
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-local" defaults
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-fixrandomemac" start 10 2 3 4 5 . stop
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-ondemandcpufreq" start 80 2 3 4 5 . stop
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d "cubian-gpiopermission" start 80 2 3 4 5 . stop

# clean cache
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get clean

if promptyn "Install Personal Stuff?"; then
    installPersonalStuff
fi
}

patchRootfs(){
# copy new files from $1
setupfsupdatebase
rsync --exclude *.patch -av ${FS_UPDATE_REPO_BASE}/$1/* ${ROOTFS_DIR}

# patch common files
find ${FS_UPDATE_REPO_BASE}/$1/ -type f -name "*.patch" | while read patch; do applyPatch "${FS_UPDATE_REPO_BASE}/$1/" "$patch";done
}

umountSDSafe() {
sync
sleep 5
for n in ${SD_PATH}*;do
    if [ "${SD_PATH}" != "$n" ];then
        if mount|grep ${n};then
            echo "umounting ${n}"
            umount -l $n
            sleep 2
        fi
    fi
done
}

mountRoot() {
umountSDSafe
if [ ! -d ${SD_MNT_POINT} ];then
    mkdir ${SD_MNT_POINT}
fi
mount ${SD_PATH}1 ${SD_MNT_POINT}
}

ejectSD() {
if [ -b ${SD_PATH} ];then
eject ${SD_PATH}
else
echo "device ${SD_PATH} doesn't exists"
fi
}

formatSD() {
dd if=/dev/zero of=${SD_PATH} bs=1M count=1
parted ${SD_PATH} --script mklabel msdos
parted ${SD_PATH} --script -- mkpart primary 1 $1
}

installRoot() {
partprobe
mkfs.ext4 ${SD_PATH}1
e2label ${SD_PATH}1 cubieboard
sync

mountRoot
cd ${ROOTFS_DIR}
tar --exclude=qemu-arm-static --exclude=resolv.conf -cf - . | tar -C ${SD_MNT_POINT} -xvf -
umount ${SD_MNT_POINT} >>/dev/null 2>&1
cd ${PWD}
}

installMBR(){
sunxispl="${CURRENT_UBOOT}/spl/sunxi-spl.bin"
uboot="${CURRENT_UBOOT}/u-boot.bin"
echoRed "install spl from ${sunxispl}"
dd if=$sunxispl of=${SD_PATH} bs=1024 seek=8
echoRed "install uboot from ${uboot}"
dd if=$uboot of=${SD_PATH} bs=1024 seek=32
}

removeSD(){
umountSDSafe
ejectSD
}

echoStage () {
echo ""
echo "-- Stage $1 : $2"
echo "----------------------------------------------------------------------"
echo ""
}

show_menu(){
    NORMAL=`echo -e "\033[m"`
    MENU=`echo -e "\033[36m"` #Blue
    NUMBER=`echo -e "\033[33m"` #yellow
    FGRED=`echo -e "\033[41m"`
    RED_TEXT=`echo -e "\033[31m"`
    ENTER_LINE=`echo -e "\033[33m"`
    #echo "${MENU}    Debian Builder ${SCRIPT_VERSION}     ${NORMAL}"

    #echo ""
    echo "${NORMAL}    General options${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 1)${MENU} Setup enviroment ${NORMAL}"
    echo "${MENU}${NUMBER} 2)${MENU} Download or Update source ${NORMAL}"

    echo ""
    echo "${NORMAL}    Root file system${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 10)${MENU} Download rootfs ${NORMAL}"
    echo "${MENU}${NUMBER} 11)${MENU} Install base system ${NORMAL}"
    echo "${MENU}${NUMBER} 12)${MENU} Install packages ${NORMAL}"
    echo "${MENU}${NUMBER} 13)${MENU} Config Network & Locale & Timezone ${NORMAL}"
    echo "${MENU}${NUMBER} 14)${MENU} Config Users & Apply fsupdate${NORMAL}"

    echo ""
    echo "${NORMAL}    A10${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 101)${MENU} Build Linux kernel(3.4.43) for A10 ${NORMAL}"
    echo "${MENU}${NUMBER} 102)${MENU} Install UBoot & kernel & modules${NORMAL}"
    echo "${MENU}${NUMBER} 103)${MENU} Install to device ${SD_PATH} ${NORMAL}"
    echo "${MENU}${NUMBER} 104)${MENU} Make disk image A10"

    echo ""
    echo "${NORMAL}    A20${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 201)${MENU} Build Linux kernel 3.3 for A20 ${NORMAL}"
    echo "${MENU}${NUMBER} 202)${MENU} Build Linux kernel 3.4 for A20 ${NORMAL}"
    echo "${MENU}${NUMBER} 203)${MENU} Install UBoot & kernel & modules${NORMAL}"
    echo "${MENU}${NUMBER} 204)${MENU} Install to device ${SD_PATH} ${NORMAL}"
    echo "${MENU}${NUMBER} 205)${MENU} Make disk image A20"

    echo ""
    echo "${NORMAL}    Build U-Boot${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 301)${MENU}  Build u-boot for A10 MMC ${NORMAL}"
    echo "${MENU}${NUMBER} 302)${MENU}  Build u-boot for A10 NAND ${NORMAL}"
    echo "${MENU}${NUMBER} 303)${MENU}  Build u-boot for A20 MMC ${NORMAL}"
    echo "${MENU}${NUMBER} 304)${MENU}  Build u-boot for A20 NAND ${NORMAL}"
    echo "${MENU}${NUMBER} 305)${MENU}  Build u-boot for A20 MMMC FIXED MACHID ${NORMAL}"
    echo "${MENU}${NUMBER} 306)${MENU}  Build u-boot for A20 NAND FIXED MACHID ${NORMAL}"

    echo ""
    echo "${NORMAL}    Build sunxi-tools${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 401)${MENU} Build sunxi-tools x86 ${NORMAL}"
	echo "${MENU}${NUMBER} 402)${MENU} Build sunxi-tolls arm a10(mbr311)${NORMAL}"
	echo "${MENU}${NUMBER} 403)${MENU} Build sunxi-tolls arm a20(mbr411)${NORMAL}"

    echo ""
    echo "${NORMAL}    Misc Commands${NORMAL}"
    echo ""

    echo "${MENU}${NUMBER} 501)${MENU}  Create linux-headers-3.4.43 ${NORMAL}"
    echo "${MENU}${NUMBER} 502)${MENU}  Add default installed package ${NORMAL}"

    echo ""
    echo "${ENTER_LINE}Please enter the option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"

    if [ ! -z "$1" ]
    then
        echo $1;
    fi
    read opt
}

isRoot
clear
show_menu
while [ ! -z "$opt" ];do
    case $opt in
    1) clear;
        echoRed "Set up your enviroment `uname -v`";
        setupTools
        echoRed "Done";
        show_menu
        ;;
    2) clear;
        echoRed "Clone repository uBoot,kernel,tools,boards from github";
        initRepo
        if promptyn "Do you want update these repositories?"; then
            git submodule foreach git pull
        fi
        echoRed "Done";
        show_menu
        ;;
    10) clear;
        echoRed "Download rootfs";
        if [ -d ${ROOTFS_DIR} ];then
           if promptyn "The rootfs exists, do you want delete it?"; then
               rm -rf ${ROOTFS_DIR}
           fi
        fi
        if [ -f ${ROOTFS_BACKUP} ];then
           if promptyn "Found a backup of rootfs, restore from it?"; then
               if [ -d ${ROOTFS_DIR} ];then
                   rm -rf ${ROOTFS_DIR}
               fi
               echoRed "Restore from rootfs";
               tar -xzPf ${ROOTFS_BACKUP}
               echoRed "Done";
               show_menu
               continue
           fi
        fi
        if promptyn "Download rootfs, it may take a few minutes, continue?"; then
            echoRed "Start download rootfs";
            downloadSys
            echoRed "Make a backup of the clean rootfs";
            if [ -f ${ROOTFS_BACKUP} ];then
                rm ${ROOTFS_BACKUP}
            fi
            tar -czPf ${ROOTFS_BACKUP} ${ROOTFS_DIR}
        fi
        echoRed "Done";
        show_menu
        ;;
    11) clear;
        echoRed "Install base system";
        if [ -f ${BASESYS_BACKUP} ];then
           if promptyn "Found a backup of base system, restore from it?"; then
               if [ -d ${ROOTFS_DIR} ];then
                   rm -rf ${ROOTFS_DIR}
               fi
               echoRed "Restore basesystem, please wait";
               tar -xzPf ${BASESYS_BACKUP}
               echoRed "Base System Restored";
               show_menu
               continue
           fi
        fi
        if [ -d ${ROOTFS_DIR} ];then
            if promptyn "Are you sure to install the base system?"; then
               echoRed "Installing base system, it may take a while";
               installBaseSys
               echoRed "Base system installed";
            fi
            echoRed "Make a backup of the clean base system";
            if [ -f ${BASESYS_BACKUP} ];then
                rm ${BASESYS_BACKUP}
            fi
            tar -czPf ${BASESYS_BACKUP} ${ROOTFS_DIR}
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi
        echoRed "Done";
        show_menu
        ;;
    12) clear;
        echoRed "Install packages";
        if [ -f ${BASESYS_PKG_BACKUP} ];then
           if promptyn "Found a backup of base system with packages, restore from it?"; then
               if [ -d ${ROOTFS_DIR} ];then
                   rm -rf ${ROOTFS_DIR}
               fi
               echoRed "Restore basesystem with packages, please wait";
               tar -xzPf ${BASESYS_PKG_BACKUP}
               echoRed "Base System with packages Restored";
               show_menu
               continue
           fi
        fi
        if [ -d ${ROOTFS_DIR} ];then
            echoRed "${DEB_EXTRAPACKAGES}";
            installPackages
            echoRed "Package ${DEB_EXTRAPACKAGES} installed to the system";
            echoRed "Make a backup of the system";
            if [ -f ${BASESYS_PKG_BACKUP} ];then
                rm ${BASESYS_PKG_BACKUP}
            fi
            tar -czPf ${BASESYS_PKG_BACKUP} ${ROOTFS_DIR}
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi
        echoRed "Done";
        show_menu
        ;;
    13) clear;
        if [ -f ${BASESYS_CONFIG_BACKUP} ];then
           if promptyn "Found a backup of standard configed system, restore from it?"; then
               if [ -d ${ROOTFS_DIR} ];then
                   rm -rf ${ROOTFS_DIR}
               fi
               echoRed "Restore basesystem with standard configed, please wait";
               tar -xzPf ${BASESYS_CONFIG_BACKUP}
               echoRed "Base System with standard configed Restored";
               show_menu
               continue
           fi
        fi
        if [ -d ${ROOTFS_DIR} ];then
            echoRed "Config Network";
                configNetwork
            echoRed "Net work configed";
            echoRed "Config System";
                configSys
            echoRed "System configed";
            echoRed "Make a backup of the system";
            if [ -f ${BASESYS_CONFIG_BACKUP} ];then
                rm ${BASESYS_CONFIG_BACKUP}
            fi
            tar -czPf ${BASESYS_CONFIG_BACKUP} ${ROOTFS_DIR}
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi

        echoRed "Done";
        show_menu
        ;;
    14) clear;
        if [ -f ${BASESYS_FINAL_BACKUP} ];then
           if promptyn "Found a backup of final configed system, restore from it?"; then
               if [ -d ${ROOTFS_DIR} ];then
                   rm -rf ${ROOTFS_DIR}
               fi
               echoRed "Restore basesystem with final configed, please wait";
               tar -xzPf ${BASESYS_FINAL_BACKUP}
               echoRed "Base System with final configed Restored";
               show_menu
               continue
           fi
        fi
        if [ -d ${ROOTFS_DIR} ];then
            echoRed "Install Utilites and personal stuff"
            finalConfig
            echoRed "Make a backup of the system";
            if [ -f ${BASESYS_FINAL_BACKUP} ];then
                rm ${BASESYS_FINAL_BACKUP}
            fi
            tar -czPf ${BASESYS_FINAL_BACKUP} ${ROOTFS_DIR}
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi
        echoRed "Done";
        show_menu
        ;;

    101) clear;
        echoRed "Build Linux kernel";
        gitOpt="--git-dir=${LINUX_REPO_A10}/.git --work-tree=${LINUX_REPO_A10}/"
        if [ ! -d $LINUX_REPO_A10 ];then
            git clone $LINUX_REPO $LINUX_REPO_A10
        fi
        gitOpt="--git-dir=${LINUX_REPO_A10}/.git --work-tree=${LINUX_REPO_A10}/"
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $LINUX_A10 ]; then
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $LINUX_A10
        fi
        git $gitOpt pull
        echoRed "Using configuration file $LINUX_CONFIG_BASE_SUN4I";
        cp -f $LINUX_CONFIG_BASE_SUN4I ${LINUX_REPO_A10}/.config
        if promptyn "Reconfigure kernel?"; then
            make -C $LINUX_REPO_A10 ARCH=arm menuconfig
        fi
        make -j${CPU_CORES} -C $LINUX_REPO_A10 ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- uImage modules
        CURRENT_KERNEL="$LINUX_REPO_A10"
        echoRed "Done";
        show_menu
        ;;
    102) clear;
        if [ -d ${ROOTFS_DIR} ];then
            echoRed "Install UBoot";
            if [ -f "${ROOTFS_DIR}/boot/boot.scr" ] && [ -f "${ROOTFS_DIR}/boot/script.bin" ];then
                if promptyn "UBoot has been installed, reinstall?"; then
                    installBootscr
                    installFex $FEX_SUN4I
                fi
            else
                installBootscr
                installFex $FEX_SUN4I
            fi
            echoRed "UBoot installed";
            echoRed "Install linux kernel";
            if [ -f "${ROOTFS_DIR}/boot/uImage" ];then
                if promptyn "Kernel has been installed, reinstall?"; then
                    installKernel
                fi
            else
                installKernel
            fi
            echoRed "Kernel installed";
            echoRed "Patch rootfs for A10"
            patchRootfs $A10
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi

        echoRed "Done";
        show_menu
        ;;
    103) clear;
        echoRed "Install to your device ${SD_PATH}"
        echoRed "Device info"
        fdisk -l | grep ${SD_PATH}
        if promptyn "All the data on ${SD_PATH} will be destoried, continue?"; then
            echoRed "umount ${SD_PATH}"
            umountSDSafe
            echoRed "Done";
            echoRed "Formating"
            formatSD 1024
            echoRed "Done";
            echoRed "Transferring data, it may take a while, please be patient, DO NOT UNPLUG YOUR DEVICE, it will be removed automaticlly when finished";
            installRoot
            CURRENT_UBOOT="$UBOOT_REPO_A10_MMC"
            installMBR
            removeSD
            echoRed "Done";
            echoRed "Congratulations,you can safely remove your sd card";
            echoRed "Now press Enter to quit the program";
        fi
        show_menu
        ;;
    104) clear;
        echoRed "make disk image 1GB"
        IMAGE_FILE="${CWD}/${DEB_HOSTNAME}-base-r${RELEASE_VERSION_A10}-arm-a10.img"
        IMAGE_FILESIZE=1024
        echo "create disk file ${IMAGE_FILE}"
        dd if=/dev/zero of=$IMAGE_FILE bs=1M count=$IMAGE_FILESIZE
        SD_PATH_OLD=${SD_PATH}
        SD_PATH_RAW=`losetup -f --show ${IMAGE_FILE}`
        echo "create device ${SD_PATH_RAW}"
        SD_PATH=${SD_PATH_RAW}
        echo "format device"
        formatSD 1001
        SD_PATH="${SD_PATH}p"
        echo "Transferring system"
        installRoot
        SD_PATH=${SD_PATH_RAW}
        echo "Install MBR"
        CURRENT_UBOOT="$UBOOT_REPO_A10_MMC"
        installMBR
        echo "umount device ${SD_PATH}"
        umountSDSafe
        losetup -d ${SD_PATH}
        SD_PATH=${SD_PATH_OLD}
        echo  "compressing image"
        #7z a -mx=9 ${IMAGE_FILE}.7z $IMAGE_FILE
        show_menu
        ;;

    201) clear;
        echoRed "Build Linux kernel 3.3 for A20";
        gitOpt="--git-dir=${LINUX_REPO_A20_3_3}/.git --work-tree=${LINUX_REPO_A20_3_3}/"
        if [ ! -d $LINUX_REPO_A20_3_3 ];then
            git clone $LINUX_REPO $LINUX_REPO_A20_3_3
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $LINUX_A20_3_3 ]; then
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $LINUX_A20_3_3
        fi
        git $gitOpt pull
        echoRed "Using configuration file $LINUX_CONFIG_BASE_SUN7I_3_3";
        cp -f $LINUX_CONFIG_BASE_SUN7I_3_3 ${LINUX_REPO_A20_3_3}/.config
        if promptyn "Reconfigure kernel?"; then
            make -C $LINUX_REPO_A20_3_3 ARCH=arm menuconfig
        fi
        make -j${CPU_CORES} -C $LINUX_REPO_A20_3_3 ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- uImage modules
        CURRENT_KERNEL="$LINUX_REPO_A20_3_3"
        echoRed "Done";
        show_menu
        ;;
    202) clear;
        echoRed "Build Linux kernel 3.4 for A20";
        gitOpt="--git-dir=${LINUX_REPO_A20_3_4}/.git --work-tree=${LINUX_REPO_A20_3_4}/"
        if [ ! -d $LINUX_REPO_A20_3_4 ];then
            git clone $LINUX_REPO $LINUX_REPO_A20_3_4
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $LINUX_A20_3_4 ]; then
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $LINUX_A20_3_4
        fi
        git $gitOpt pull
        echoRed "Using configuration file $LINUX_CONFIG_BASE_SUN7I_3_4";
        cp -f $LINUX_CONFIG_BASE_SUN7I_3_4 ${LINUX_REPO_A20_3_4}/.config
        if promptyn "Reconfigure kernel?"; then
            make -C $LINUX_REPO_A20_3_4 ARCH=arm menuconfig
        fi
        setupLinaroToolchain
        make -j${CPU_CORES} -C $LINUX_REPO_A20_3_4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
        CURRENT_KERNEL="$LINUX_REPO_A20_3_4"
        echoRed "Done";
        show_menu
        ;;
    203) clear;
        if [ -d ${ROOTFS_DIR} ];then
            echoRed "Install UBoot";
            if [ -f "${ROOTFS_DIR}/boot/boot.scr" ] && [ -f "${ROOTFS_DIR}/boot/script.bin" ];then
                if promptyn "UBoot has been installed, reinstall?"; then
                    installBootscr
                    installFex $FEX_SUN7I
                fi
            else
                installBootscr
                installFex $FEX_SUN7I
            fi
            echoRed "UBoot installed";
            echoRed "Install linux kernel";
            if [ -f "${ROOTFS_DIR}/boot/uImage" ];then
                if promptyn "Kernel has been installed, reinstall?"; then
                    installKernel
                fi
            else
                installKernel
            fi
            echoRed "Kernel installed";
            echoRed "Patch rootfs for A20"
            patchRootfs $A20
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi
        echoRed "Done";
        show_menu
        ;;
    204) clear;
        echoRed "Install to your device ${SD_PATH}"
        echoRed "Device info"
        fdisk -l | grep ${SD_PATH}
        if promptyn "All the data on ${SD_PATH} will be destoried, continue?"; then
            echoRed "umount ${SD_PATH}"
            umountSDSafe
            echoRed "Done";
            echoRed "Formating"
            formatSD 1024
            echoRed "Done";
            echoRed "Transferring data, it may take a while, please be patient, DO NOT UNPLUG YOUR DEVICE, it will be removed automaticlly when finished";
            installRoot
			if [[ CURRENT_KERNEL="$LINUX_REPO_A20_3_3" ]];then
            	CURRENT_UBOOT="$UBOOT_REPO_A20_MMC_FIXED_MACHID"
			elif [[ CURRENT_KERNEL="$LINUX_REPO_A20_3_4" ]];then
            	CURRENT_UBOOT="$UBOOT_REPO_A20_MMC"
			fi
            installMBR
            removeSD
            echoRed "Done";
            echoRed "Congratulations,you can safely remove your sd card";
            echoRed "Now press Enter to quit the program";
        fi
        show_menu
        ;;
    205) clear;
        echoRed "make disk image 1GB"
        IMAGE_FILE="${CWD}/${DEB_HOSTNAME}-base-r${RELEASE_VERSION_A20}-arm-a20.img"
        IMAGE_FILESIZE=1024
        echo "create disk file ${IMAGE_FILE}"
        dd if=/dev/zero of=$IMAGE_FILE bs=1M count=$IMAGE_FILESIZE
        SD_PATH_OLD=${SD_PATH}
        SD_PATH_RAW=`losetup -f --show ${IMAGE_FILE}`
        echo "create device ${SD_PATH_RAW}"
        SD_PATH=${SD_PATH_RAW}
        echo "format device"
        formatSD 1001
        SD_PATH="${SD_PATH}p"
        echo "Transferring system"
        installRoot
        SD_PATH=${SD_PATH_RAW}
        echo "Install MBR"
        CURRENT_UBOOT="$UBOOT_REPO_A20_MMC"
        installMBR
        echo "umount device ${SD_PATH}"
        umountSDSafe
        losetup -d ${SD_PATH}
        SD_PATH=${SD_PATH_OLD}
        echo  "compressing image"
        #7z a -mx=9 ${IMAGE_FILE}.7z $IMAGE_FILE
        show_menu
        ;;
    301) clear;
        echoRed "Start build u-boot for A10 MMC";
        gitOpt="--git-dir=${UBOOT_REPO_A10_MMC}/.git --work-tree=${UBOOT_REPO_A10_MMC}"
        if [ ! -d $UBOOT_REPO_A10_MMC ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A10_MMC
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A10_MMC ]; then
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A10_MMC
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A10_MMC
        echoRed "Done";
        show_menu
        ;;
    302) clear;
        echoRed "Start build u-boot for A10 NAND";
        gitOpt="--git-dir=${UBOOT_REPO_A10_NAND}/.git --work-tree=${UBOOT_REPO_A10_NAND}/"
        if [ ! -d $UBOOT_REPO_A10_NAND ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A10_NAND
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A10_NAND ]; then
            echoRed "Switch branch to A10 NAND"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A10_NAND
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A10_NAND
        echoRed "Done";
        show_menu
        ;;
    303) clear;
		echoRed "Start build u-boot for A20 MMC";
        gitOpt="--git-dir=${UBOOT_REPO_A20_MMC}/.git --work-tree=${UBOOT_REPO_A20_MMC}/"
        if [ ! -d $UBOOT_REPO_A20_MMC ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A20_MMC
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A20_MMC ]; then
            echoRed "Switch branch to A20"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A20_MMC
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A20_MMC
        echoRed "Done";
        show_menu
        ;;
    304) clear;
        echoRed "Start build u-boot for A20 NAND";
        gitOpt="--git-dir=${UBOOT_REPO_A20_NAND}/.git --work-tree=${UBOOT_REPO_A20_NAND}/"
        if [ ! -d $UBOOT_REPO_A20_NAND ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A20_NAND
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A20_NAND ]; then
            echoRed "Switch branch to A20 NAND"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A20_NAND
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A20_NAND
        echoRed "Done";
        show_menu
        ;;
    305) clear;
		echoRed "Start build u-boot for A20 MMC FIXED MACHID";
        gitOpt="--git-dir=${UBOOT_REPO_A20_MMC_FIXED_MACHID}/.git --work-tree=${UBOOT_REPO_A20_MMC_FIXED_MACHID}/"
        if [ ! -d $UBOOT_REPO_A20_MMC_FIXED_MACHID ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A20_MMC_FIXED_MACHID
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A20_MMC_FIXED_MACHID ]; then
            echoRed "Switch branch to A20 FIXED MACHID"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A20_MMC_FIXED_MACHID
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A20_MMC_FIXED_MACHID
        echoRed "Done";
        show_menu
        ;;
    306) clear;
        echoRed "Start build u-boot for A20 NAND FIXED MACHID";
        gitOpt="--git-dir=${UBOOT_REPO_A20_NAND_FIXED_MACHID}/.git --work-tree=${UBOOT_REPO_A20_NAND_FIXED_MACHID}/"
        if [ ! -d $UBOOT_REPO_A20_NAND_FIXED_MACHID ];then
            git clone $UBOOT_REPO $UBOOT_REPO_A20_NAND_FIXED_MACHID
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $UBOOT_A20_NAND_FIXED_MACHID ]; then
            echoRed "Switch branch to A20 NAND FIXED MACHID"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $UBOOT_A20_NAND_FIXED_MACHID
        fi
        git $gitOpt pull
        buildUBoot $UBOOT_REPO_A20_NAND_FIXED_MACHID
        echoRed "Done";
        show_menu
        ;;
    401) clear;
        echoRed "Start build sunxi-tools";
        buildTools
        echoRed "Done";
        show_menu
        ;;
	402) clear;
        gitOpt="--git-dir=${SUNXI_TOOLS_REPO_ARM_A10}/.git --work-tree=${SUNXI_TOOLS_REPO_ARM_A10}/"
        if [ ! -d $SUNXI_TOOLS_REPO_ARM_A10 ];then
            git clone $SUNXI_TOOLS_REPO $SUNXI_TOOLS_REPO_ARM_A10
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $SUNXI_TOOLS_A10 ]; then
            echoRed "Switch branch to A20 NAND FIXED MACHID"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $SUNXI_TOOLS_A10
        fi
        git $gitOpt pull
		make -C $SUNXI_TOOLS_REPO_ARM_A10 clean
		#make -C $SUNXI_TOOLS_REPO_ARM_A10 CC=arm-none-linux-gnueabi-gcc CFLAGS='-Wall -static -Iinclude/' nand-part nand-part2
		make -C $SUNXI_TOOLS_REPO_ARM_A10 CC=arm-none-linux-gnueabi-gcc CFLAGS='-Wall -std=gnu99 -static -Iinclude/' fexc bin2fex fex2bin nand-part nand-part2
        show_menu
        ;;
	403) clear;
        gitOpt="--git-dir=${SUNXI_TOOLS_REPO_ARM_A20}/.git --work-tree=${SUNXI_TOOLS_REPO_ARM_A20}/"
        if [ ! -d $SUNXI_TOOLS_REPO_ARM_A20 ];then
            git clone $SUNXI_TOOLS_REPO $SUNXI_TOOLS_REPO_ARM_A20
        fi
        branchName=$(git $gitOpt rev-parse --abbrev-ref HEAD)
        if [ $branchName != $SUNXI_TOOLS_A20 ]; then
            echoRed "Switch branch to A20 NAND FIXED MACHID"
            git $gitOpt checkout .
            git $gitOpt clean -df
            git $gitOpt checkout $SUNXI_TOOLS_A20
        fi
        git $gitOpt pull
		make -C $SUNXI_TOOLS_REPO_ARM_A20 clean
		#make -C $SUNXI_TOOLS_REPO_ARM_A20 CC=arm-none-linux-gnueabi-gcc CFLAGS='-Wall -static -Iinclude/' nand-part nand-part2
		make -C $SUNXI_TOOLS_REPO_ARM_A20 CC=arm-none-linux-gnueabi-gcc CFLAGS='-Wall -std=gnu99 -static -Iinclude/' fexc bin2fex fex2bin nand-part nand-part2
        show_menu
        ;;
	501) clear;
		if [[ ! -d $LINUX_HEADER_A10_3_3 ]];then
			mkdir -p $LINUX_HEADER_A10_3_3
		fi
		for file in $($CWD/utilities/createFileList.sh /usr/src/linux-headers-3.5.0-23); do
			echo $file
			linux_header_src="${LINUX_REPO_A20_3_3}/${file}"
			linux_header_dst="${LINUX_HEADER_A10_3_3}/${file}"
			mkdir -p $(dirname $linux_header_dst)
			if [[ -f ${linux_header_src} ]];then
				cp $linux_header_src $linux_header_dst
			else
				echo "!$linux_header_src" >> header_missing.txt
			fi
		done
        show_menu
		exit
        ;;
	502) clear;
        echoRed "Install packages";
        if [ ! -f ${BASESYS_PKG_BACKUP} ];then
			echoRed "file not found ${BASESYS_PKG_BACKUP}"
            show_menu
		    exit
		fi

        if [ -d ${ROOTFS_DIR} ];then
            rm -rf ${ROOTFS_DIR}
        fi
        echoRed "Restore basesystem with packages, please wait";
        tar -xzPf ${BASESYS_PKG_BACKUP}
        echoRed "Base System with packages Restored";

		while true;do
			read -p "type package name." extra_packagenames
			if [[ -n $extra_packagenames ]];then
				break
			fi
		done

		echoRed "About to install $extra_packagenames" 
		LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get update
		LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get install ${extra_packagenames}

        if [ -d ${ROOTFS_DIR} ];then
            echoRed "Package ${extra_packagenames} installed to the system";
            echoRed "Make a backup of the system";
            if [ -f ${BASESYS_PKG_BACKUP} ];then
                rm ${BASESYS_PKG_BACKUP}
            fi
            tar -czPf ${BASESYS_PKG_BACKUP} ${ROOTFS_DIR}
        else
            echo "[E] rootfs is not existed at ${ROOTFS_DIR}"
        fi
        show_menu
		exit
		;;
    *) clear;
        show_menu "$opt is invalid. please enter a number from menu."
        ;;
    esac
done
