#!/bin/bash

#################
# CONFIGURATION #
#################
# PWD="`pwd`"               # no need: variable already managed and assigned to by bash
CWD=$(cd "${0%/*}"; pwd)    # no need to shell to external command. bash can do that. 
                            # needed at all?  IMHO changing to a directory, then printing it
                            # is same as assigning directly:    CWD="${0%/*}"

source ${CWD}/fns.sh

# This is the script verion
SCRIPT_VERSION="1.0"
RELEASE_VERSION="3"
DEVELOPMENT_CODE="argon"

# This will be the hostname of the cubieboard
DEB_HOSTNAME="Cubian"

# Not all packages can be install this way.
# DEB_EXTRAPACKAGES="nvi locales ntp ssh expect"
# Currently ntp module triggers an error when install
DEB_WIRELESS_TOOLS="wireless-tools wpasupplicant"
DEB_TEXT_EDITORS="editor nvi vim"                       # editor managed by debian's alternatives system,
                                                        # and therefore ought to reflect user preference
DEB_TEXT_UTILITIES="locales ssh expect sudo"
DEB_ADMIN_UTILITIES="inotify-tools ifplugd ntpdate rsync parted lsof psmisc"
DEB_EXTRAPACKAGES="${DEB_TEXT_EDITORS} ${DEB_TEXT_UTILITIES} ${DEB_WIRELESS_TOOLS} ${DEB_ADMIN_UTILITIES}" 

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
ROOTFS_BACKUP="${DEVELOPMENT_CODE}.rootfs.cleanbackup.tar.gz"

# Base system backup
BASESYS_BACKUP="${DEVELOPMENT_CODE}.basesys.cleanbackup.tar.gz"

# Base system has package backup
BASESYS_PKG_BACKUP="${DEVELOPMENT_CODE}.basesys.pkg.cleanbackup.tar.gz"

# Base system with basic standard config without personal stuff
BASESYS_CONFIG_BACKUP="${DEVELOPMENT_CODE}.basesys.config.cleanbackup.tar.gz"

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

TOOLCHAIN="${CWD}/toolchain/arm-2010.09"
export PATH=${TOOLCHAIN}/bin:$PATH

setupTools() {
sudo add-apt-repository ppa:linaro-maintainers/tools
apt-get update

installpackages "debootstrap" "qemu-user-static" "build-essential" "u-boot-tools" "git" "binfmt-support" "libusb-1.0-0-dev" "pkg-config" "libncurses5-dev" "debian-archive-keyring" "expect" "kpartx"
}

initRepo() {
git submodule init
git submodule update
}

buildUBoot() {
make -C ${CWD}/u-boot-sunxi/ distclean CROSS_COMPILE=arm-none-linux-gnueabi-
make -C ${CWD}/u-boot-sunxi/ cubieboard CROSS_COMPILE=arm-none-linux-gnueabi-
}

buildKernel() {
cp linux-sunxi/arch/arm/configs/sun4i_defconfig linux-sunxi/.config
make -C ${CWD}/linux-sunxi/ ARCH=arm menuconfig
make -j4 -C ${CWD}/linux-sunxi/ ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- uImage modules
}

buildTools() {
make -C ${CWD}/sunxi-tools/ clean
make -C ${CWD}/sunxi-tools/ all
}

prepareEnv() {
# install qemu
test -f ${ROOTFS_DIR}/usr/bin/qemu-arm-static ||
    cp $(which qemu-arm-static) ${ROOTFS_DIR}/usr/bin

test -f ${ROOTFS_DIR}/etc/resolv.conf ||
    cp /etc/resolv.conf ${ROOTFS_DIR}/etc/
}

downloadSys() {
test -d ${ROOTFS_DIR} &&
    rm -rf ${ROOTFS_DIR
}

mkdir --parents ${ROOTFS_DIR}
debootstrap --foreign --verbose --arch armhf wheezy ${ROOTFS_DIR}/ http://http.debian.net/debian/
}

installBaseSys() {
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

installPackages() {
prepareEnv
# install extra modules
test -n "${DEB_EXTRAPACKAGES}" &&
   LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get -y install ${DEB_EXTRAPACKAGES}
}

installUBoot() {
cat > ${ROOTFS_DIR}/boot/boot.cmd <<END
setenv bootargs console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x800p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
END
mkimage -C none -A arm -T script -d ${ROOTFS_DIR}/boot/boot.cmd ${ROOTFS_DIR}/boot/boot.scr

FEX_FILE=cubieboard_${DEVELOPMENT_CODE}.fex
cp ${CWD}/sunxi-boards/sys_config/a10/${FEX_FILE} ${ROOTFS_DIR}/boot/
cat >> ${ROOTFS_DIR}/boot/${FEX_FILE} <<END

[dynamic]
MAC = "${MAC_ADDRESS}"
END

# overlock memory
#sed -i 's/^dram_clk = 480$/dram_clk = 500/' ${ROOTFS_DIR}/boot/cubieboard.fex

${CWD}/sunxi-tools/fex2bin ${ROOTFS_DIR}/boot/${FEX_FILE} ${ROOTFS_DIR}/boot/script.bin
}

installKernel() {
cp ${CWD}/linux-sunxi/arch/arm/boot/uImage ${ROOTFS_DIR}/boot
make -C ${CWD}/linux-sunxi INSTALL_MOD_PATH=${ROOTFS_DIR} ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- modules_install
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
test -f $bakfile ||
    cp $1 $bakfile
}

configSys() {
prepareEnv

# prompt to config local and timezone
promptyn "Configure locale and timezone data?" &&
    test -n "${DPKG_RECONFIG}" &&
        LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg-reconfigure ${DPKG_RECONFIG}
}

installPersonalStuff() {
NETWORK_CFG=`${CWD}/network_cfg.sh`
cat >> ${ROOTFS_DIR}/etc/network/interfaces <<END

#
${NETWORK_CFG}
END
}

finalConfig() {
prepareEnv

echo ${DEB_HOSTNAME} > ${ROOTFS_DIR}/etc/hostname

# the backfile file only create one time
backupFile ${ROOTFS_DIR}/etc/inittab
backupFile ${ROOTFS_DIR}/etc/fstab
backupFile ${ROOTFS_DIR}/etc/modules
backupFile ${ROOTFS_DIR}/etc/hosts
backupFile ${ROOTFS_DIR}/etc/ssh/sshd_config

# restore from initial file
restoreFile ${ROOTFS_DIR}/etc/inittab
restoreFile ${ROOTFS_DIR}/etc/fstab
restoreFile ${ROOTFS_DIR}/etc/modules
restoreFile ${ROOTFS_DIR}/etc/hosts
restoreFile ${ROOTFS_DIR}/etc/ssh/sshd_config

echo "T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100" >> ${ROOTFS_DIR}/etc/inittab

cat >> ${ROOTFS_DIR}/etc/fstab <<END
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
/dev/mmcblk0p1	/		ext4	defaults	0	1
/dev/mmcblk0p2	swap		swap	defaults	0	0
END

echo "127.0.0.1 ${DEB_HOSTNAME}" >> ${ROOTFS_DIR}/etc/hosts 

cat >> ${ROOTFS_DIR}/etc/modules <<END

#For SATA Support
sw_ahci_platform

#Display and GPU
lcd
hdmi
ump
disp
mali
mali_drm
END

# prohibit root user ssh
sed -i 's/^PermitRootLogin yes$/PermitRootLogin no/' ${ROOTFS_DIR}/etc/ssh/sshd_config
# change default ssh port
sed -i 's/^Port 22$/Port 36000/' ${ROOTFS_DIR}/etc/ssh/sshd_config
# allow 5 unauthenticated clients maximium
cat >> ${ROOTFS_DIR}/etc/ssh/sshd_config <<END

MaxStartups 5
END

# config user accounts
cat > ${ROOTFS_DIR}/tmp/initsys.sh <<END
#!/bin/bash
# add default user
if [ -z "\$(getent passwd ${DEFAULT_USERNAME})" ];then
    useradd -m -s /bin/bash ${DEFAULT_USERNAME}
fi

# set user
echo "${DEFAULT_USERNAME}:${DEFAULT_PASSWD}"|chpasswd

# disable root user
passwd -l root

# allow the default user has su privileges
cat > /etc/sudoers.d/sudousers <<DNE
${DEFAULT_USERNAME} ALL=(ALL) NOPASSWD:ALL # Admins can do anthing w/o a password
%cubie ALL=(ALL) NOPASSWD:ALL # Cubie group can do anthing w/o a password
DNE
chmod 0440 /etc/sudoers.d/sudousers
END
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} chmod +x /tmp/initsys.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} /tmp/initsys.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} rm /tmp/initsys.sh

# backup some scripts
backupFile ${ROOTFS_DIR}/etc/default/ifplugd
backupFile ${ROOTFS_DIR}/etc/default/ntpdate
backupFile ${ROOTFS_DIR}/etc/ifplugd/ifplugd.action

# copy scripts
cp -r ${CWD}/scripts/* ${ROOTFS_DIR}

# copy nandinstaller
cp -r ${CWD}/nandinstall ${ROOTFS_DIR}/home/cubie

# green led ctrl
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d bootlightctrl defaults
# blue led
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d networklightctrl start 20 2 3 4 5 . stop .
# network time
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} update-rc.d ntpdate defaults


# clean cache
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get clean

promptyn "Install Personal Stuff?" &&
    installPersonalStuff
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
mkdir -p ${SD_MNT_POINT}  &&
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
dd if=/dev/zero of=${SD_PATH} bs=1M count=2
parted ${SD_PATH} --script mklabel msdos
parted ${SD_PATH} --script -- mkpart primary 1 $1
parted ${SD_PATH} --script -- mkpartfs primary linux-swap $1 $(($1+1024))
}

installRoot() {
mkfs.ext4 ${SD_PATH}1
mkswap ${SD_PATH}2
sync
partprobe

mountRoot
cd ${ROOTFS_DIR}
tar --exclude=qemu-arm-static --exclude=resolv.conf -cf - . | tar -C ${SD_MNT_POINT} -xvf -
umount ${SD_MNT_POINT} >>/dev/null 2>&1
cd ${PWD}
}

installMBR(){
dd if=${CWD}/u-boot-sunxi/spl/sunxi-spl.bin of=${SD_PATH} bs=1024 seek=8
dd if=${CWD}/u-boot-sunxi/u-boot.bin of=${SD_PATH} bs=1024 seek=32
}

removeSD(){
umountSDSafe
ejectSD
}

echoStage () {
cat << END

-- Stage $1 : $2
----------------------------------------------------------------------

END
}

automaticBuild () {
if [ -b ${SD_PATH} ]; then
cat << END

CubieDebian SD Creator by Hywkar
--------------------------------

The device in ${SD_PATH} will be erased by this script.

Configuration :
                 Hostname : ${DEB_HOSTNAME}
END

  test -n "${DEB_EXTRAPACKAGES}" &&
    echo "           Extra Packages : ${DEB_EXTRAPACKAGES}"

  test -n "${DPKG_RECONFIG}" &&
    echo "    Reconfigured Packages : ${DPKG_RECONFIG}"
 
  echo ""
  if [ "${ETH0_MODE}" = "dhcp" ]; then
    echo "               IP Address : Assigned by DHCP"
  else
    echo "               IP Address : ${ETH0_IP}"
    echo "              Subnet Mask : ${ETH0_MASK}"
    echo "          Default Gateway : ${ETH0_GW}"
    echo "                      DNS : ${DNS1} ${DNS2}"
    echo "            Search Domain : ${DNS_SEARCH}"  
  fi
  echo "              Mac Address : ${MAC_ADDRESS}"
  echo ""
  if promptyn "Shall we proceed?"; then
    echoStage 1 "Setting up build environment"
    setupTools
    echoStage 2 "Cloning repositories"
    initRepo
    echoStage 3 "Building U-Boot"
    buildUBoot
    echoStage 4 "Building Kernel"
    buildKernel
    echoStage 5 "Building Tools"
    buildTools
    echoStage 6 "Installing BootStrap and Packages"
    downloadSys
    installBaseSys
    echoStage 7 "Installing Kernel"
    installKernel
    echoStage 8 "Configuring U-Boot"
    installUBoot
    echoStage 9 "Configuring Networking"
    configNetwork
    echoStage 10 "Formatting SD Card"
    formatSD 2048
    echoStage 11 "Transfering Debian to SD Card"
    installRoot  
    installMBR  
    removeSD
    echo ""
    echo "All done"
    echo ""
  else
    echo "Nothing done..."
  fi
else
  echo "Please edit the configuration section of this script and set"
  echo "SD_PATH to the device path of your SD card."
fi
}

show_menu() {
NORMAL=$(echo -e "\033[m")
MENU=$(echo -e "\033[36m") #Blue
NUMBER=$(echo -e "\033[33m") #yellow
FGRED=$(echo -e "\033[41m")
RED_TEXT=$(echo -e "\033[31m")
ENTER_LINE=$(echo -e "\033[33m")

cat << END
${MENU}    Debian Builder ${SCRIPT_VERSION}     ${NORMAL}
${MENU}${NUMBER} 1)${MENU} Setup enviroment ${NORMAL}
${MENU}${NUMBER} 2)${MENU} Download or Update Linux source ${NORMAL}
${MENU}${NUMBER} 3)${MENU} Build tools ${NORMAL}
${MENU}${NUMBER} 4)${MENU} Build Linux kernel ${NORMAL}
${MENU}${NUMBER} 5)${MENU} Download rootfs ${NORMAL}
${MENU}${NUMBER} 6)${MENU} Install base system ${NORMAL}
${MENU}${NUMBER} 7)${MENU} Install packages ${NORMAL}
${MENU}${NUMBER} 8)${MENU} Install UBoot & kernel & config System ${NORMAL}
${MENU}${NUMBER} 9)${MENU} Install Utilities & Personal stuff ${NORMAL}
${MENU}${NUMBER} 10)${MENU} Install to device ${SD_PATH} ${NORMAL}
${MENU}${NUMBER} 11)${MENU} Make disk image

${NORMAL}    Test Commands (Use them only if you know what you are doing)${NORMAL}

${MENU}${NUMBER} 12)${MENU} recompile cubieboard.fex to script.bin on ${SD_PATH}1 /boot ${NORMAL}

${ENTER_LINE}Please enter the option and enter or ${RED_TEXT}enter to exit. ${NORMAL}
END

test -z "$1" || echo $1;
read opt
}

isRoot
clear
show_menu
while [ ! -z "$opt" ]
do
    if [ -z "$opt" ]            # appears unneeded - loop body ought never be executed if $opt empty
    then
        exit
    fi
    
# --- rest of file not reviewed --- 
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
    3) clear;
        echoRed "Start build uBoot";
        buildUBoot
        echoRed "Done";
        echoRed "Start build sunxi-tools";
        buildTools
        echoRed "Done";
        show_menu
        ;;
    4) clear;
        echoRed "Build Linux kernel";
        if promptyn "Reconfigure kernel?"; then
            make -C ${CWD}/linux-sunxi/ ARCH=arm menuconfig
        fi
        make -j4 -C ${CWD}/linux-sunxi/ ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- uImage modules
        echoRed "Done";
        show_menu
        ;;
    5) clear;
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
    6) clear;
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
    7) clear;
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
    8) clear;
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
            echoRed "Install UBoot";
            if [ -f "${ROOTFS_DIR}/boot/boot.scr" ] && [ -f "${ROOTFS_DIR}/boot/script.bin" ];then
                if promptyn "UBoot has been installed, reinstall?"; then
                    installUBoot
                fi
            else
                installUBoot
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
    9) clear;
        echoRed "Install Utilites and personal stuff"
        finalConfig
        echoRed "Done";
        show_menu
        ;;
    10) clear;
        echoRed "Install to your device ${SD_PATH}"
        echoRed "Device info"
        fdisk -l | grep ${SD_PATH}
        if promptyn "All the data on ${SD_PATH} will be destoried, continue?"; then
            echoRed "umount ${SD_PATH}"
            umountSDSafe
            echoRed "Done";
            echoRed "Formating"
            formatSD 2662
            echoRed "Done";
            echoRed "Transferring data, it may take a while, please be patient, DO NOT UNPLUG YOUR DEVICE, it will be removed automaticlly when finished";
            installRoot
            installMBR
            removeSD
            echoRed "Done";
            echoRed "Congratulations,you can safely remove your sd card";
            echoRed "Now press Enter to quit the program";
        fi
        show_menu
        ;;
    11) clear;
        echoRed "make disk image 4GB"
        IMAGE_FILE="${CWD}/${DEB_HOSTNAME}-base-r${RELEASE_VERSION}-arm.img"
        IMAGE_FILESIZE=3686 #
        echo "create disk file ${IMAGE_FILE}"
        dd if=/dev/zero of=$IMAGE_FILE bs=1M count=$IMAGE_FILESIZE
        SD_PATH_OLD=${SD_PATH}
        SD_PATH_RAW=`losetup -f --show ${IMAGE_FILE}`
        echo "create device ${SD_PATH_RAW}"
        SD_PATH=${SD_PATH_RAW}
        echo "format device"
        formatSD 2662
        SD_PATH="${SD_PATH}p"
        echo "Transferring system"
        installRoot
        SD_PATH=${SD_PATH_RAW}
        echo "Install MBR"
        installMBR
        echo "umount device ${SD_PATH}"
        umountSDSafe
        losetup -d ${SD_PATH}
        SD_PATH=${SD_PATH_OLD}
        echo  "compressing image"
        bzip2 -zkfv9 $IMAGE_FILE
        if ! testbz2 "${IMAGE_FILE}.bz2";then
            echo "PLEASE REGENERATE THE IMAGE FILE!!!"
            pause
        else
            echo "PASS"
        fi
        show_menu
        ;;
    12) clear;
        echoRed "recompile cubieboard.fex to script.bin on ${SD_PATH}1 /boot ${NORMAL}"
        umountSDSafe
        sleep 1
        mountRoot
        if promptyn "start recompile?"; then
            SD_BOOT_DIR="${SD_MNT_POINT}/boot"
            SD_FEX_FILE="${SD_BOOT_DIR}/cubieboard.fex"
            SD_SCRIPT_BIN_FILE="${SD_BOOT_DIR}/script.bin"

            if [ -f ${SD_FEX_FILE} ];then
                echoRed "hash `md5sum ${SD_SCRIPT_BIN_FILE}`"
            else
                echoRed "[W] script.bin not founded"
            fi

            # recompile cubieboard.fex to script.bin
            ${CWD}/sunxi-tools/fex2bin ${SD_FEX_FILE} ${SD_SCRIPT_BIN_FILE}
            echoRed "hash `md5sum ${SD_SCRIPT_BIN_FILE}`"
            echoRed "Done"
        fi
        if promptyn "remove ${SD_PATH}?"; then
            umountSDSafe
            sleep 1
            ejectSD
            echoRed "Your disk removed"
        fi
        show_menu
        ;;
    *) clear;
        show_menu "$opt is invalid. please enter a number from menu."
        ;;
    esac
done
