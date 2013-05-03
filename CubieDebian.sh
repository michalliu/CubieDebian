#!/bin/sh

#################
# CONFIGURATION #
#################
# This is the script verion
SCRIPT_VERSION="1.0"

# This will be the hostname of the cubieboard
DEB_HOSTNAME="argon"

# Not all packages can be install this way.
# DEB_EXTRAPACKAGES="nvi locales ntp ssh expect"
# Currently ntp module triggers an error when install
DEB_EXTRAPACKAGES="nvi locales ssh expect"

# Not all packages can (or should be) reconfigured this way.
DPKG_RECONFIG="locales tzdata"

# Make sure this is valid and is really your SD..
SD_PATH="/dev/sdb"

# MAC will be encoded in script.bin
#MAC_ADDRESS="0DEADBEEFBAD"
MAC_ADDRESS="008010EDDF01"

# If you want to use DHCP, use the following
ETH0_MODE="dhcp"

# Rootfs Dir
ROOTFS_DIR="`pwd`/rootfs/${DEB_HOSTNAME}-armfs/"

# Rootfs backup
ROOTFS_BACKUP="${DEB_HOSTNAME}.rootfs.cleanbackup.tar.gz"

# Base system backup
BASESYS_BACKUP="${DEB_HOSTNAME}.basesys.cleanbackup.tar.gz"

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

setupTools() {
apt-get install build-essential u-boot-tools qemu-user-static debootstrap git binfmt-support libusb-1.0-0-dev pkg-config libncurses5-dev debian-archive-keyring expect

cat > /etc/apt/sources.list.d/emdebian.list <<END
deb http://www.emdebian.org/debian/ wheezy main
deb http://www.emdebian.org/debian/ sid main
END

apt-get install emdebian-archive-keyring
apt-get update

apt-get install gcc-4.5-arm-linux-gnueabihf
for i in /usr/bin/arm-linux-gnueabi*-4.5 ; do ln -f -s $i ${i%%-4.5} ; done
}

gitClone() {
git clone https://github.com/linux-sunxi/u-boot-sunxi.git
git clone https://github.com/linux-sunxi/linux-sunxi.git -b sunxi-3.4
git clone https://github.com/linux-sunxi/sunxi-tools.git
git clone https://github.com/linux-sunxi/sunxi-boards.git
}

buildUBoot() {
make -C ./u-boot-sunxi/ distclean CROSS_COMPILE=arm-linux-gnueabihf-
make -C ./u-boot-sunxi/ cubieboard CROSS_COMPILE=arm-linux-gnueabihf-
}

buildKernel() {
cp linux-sunxi/arch/arm/configs/sun4i_defconfig linux-sunxi/.config
make -C ./linux-sunxi/ ARCH=arm menuconfig
make -j4 -C ./linux-sunxi/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
}

buildTools() {
make -C ./sunxi-tools/ clean
make -C ./sunxi-tools/ all
}

cleanupSys() {
rm ${ROOTFS_DIR}/usr/bin/qemu-arm-static
rm ${ROOTFS_DIR}/etc/resolv.conf
}

downloadSys(){
if [ -d ${ROOTFS_DIR} ];then
    rm -rf ${ROOTFS_DIR}
fi
mkdir --parents ${ROOTFS_DIR}
#debootstrap --foreign --arch armhf wheezy ${ROOTFS_DIR}/ http://mirrors.sohu.com/debian/
debootstrap --foreign --arch armhf wheezy ${ROOTFS_DIR}/ http://http.debian.net/debian/
}

installBaseSys(){
cp /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} /debootstrap/debootstrap --second-stage
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg --configure -a
echo ${DEB_HOSTNAME} > ${ROOTFS_DIR}/etc/hostname
cp /etc/resolv.conf ${ROOTFS_DIR}/etc/
cat > ${ROOTFS_DIR}/etc/apt/sources.list <<END
deb http://http.debian.net/debian/ wheezy main contrib non-free
#deb http://mirrors.sohu.com/debian/ wheezy main contrib non-free
END
echo deb http://security.debian.org/ wheezy/updates main contrib non-free >> ${ROOTFS_DIR}/etc/apt/sources.list
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get upgrade
cleanupSys
}

installUBoot() {
cat > ${ROOTFS_DIR}/boot/boot.cmd <<END
setenv bootargs console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x800p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
END
mkimage -C none -A arm -T script -d ${ROOTFS_DIR}/boot/boot.cmd ${ROOTFS_DIR}/boot/boot.scr

cp ./sunxi-boards/sys_config/a10/cubieboard.fex ${ROOTFS_DIR}/boot/
cat >> ${ROOTFS_DIR}/boot/cubieboard.fex <<END

[dynamic]
MAC = "${MAC_ADDRESS}"
END

./sunxi-tools/fex2bin ${ROOTFS_DIR}/boot/cubieboard.fex ${ROOTFS_DIR}/boot/script.bin
}

installKernel() {
cp ./linux-sunxi/arch/arm/boot/uImage boot
make -C ./linux-sunxi INSTALL_MOD_PATH=${ROOTFS_DIR} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install
}

configNetwork() {
cat > ${ROOTFS_DIR}/etc/network/interfaces <<END
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

configModules() {
cp /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin
if [ -n "${DEB_EXTRAPACKAGES}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get install ${DEB_EXTRAPACKAGES}
fi

if [ -n "${DPKG_RECONFIG}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg-reconfigure ${DPKG_RECONFIG}
fi
}

configSys(){
#echo ""
#echo "Please enter a new root password for ${DEB_HOSTNAME}"
#chroot ${ROOTFS_DIR} passwd 
#echo ""
echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> ${ROOTFS_DIR}/etc/inittab

cat > ${ROOTFS_DIR}/etc/fstab <<END
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext4	defaults	0	1
END

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
8188eu
END
}

formatSD() {
dd if=/dev/zero of=${SD_PATH} bs=1M count=2
parted ${SD_PATH} --script mklabel msdos
parted ${SD_PATH} --script -- mkpart primary 1 -1
mkfs.ext4 ${SD_PATH}1
sync
partprobe

dd if=./u-boot-sunxi/spl/sunxi-spl.bin of=${SD_PATH} bs=1024 seek=8
dd if=./u-boot-sunxi/u-boot.bin of=${SD_PATH} bs=1024 seek=32
}

installSD() {
mkdir mnt
mount ${SD_PATH}1 ./mnt/
cd ${ROOTFS_DIR}
tar -cf - . | tar -C ../mnt -xvf -
cd ..
sync
umount ./mnt/
rm -rf ./mnt
eject ${SD_PATH}
}

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

echoStage () {
echo ""
echo "-- Stage $1 : $2"
echo "----------------------------------------------------------------------"
echo ""
}

automaticBuild () {
if [ -b ${SD_PATH} ]; then
  echo ""
  echo "CubieDebian SD Creator by Hywkar"
  echo "--------------------------------"
  echo ""
  echo "The device in ${SD_PATH} will be erased by this script."
  echo ""
  echo "Configuration :"
  echo "                 Hostname : ${DEB_HOSTNAME}"
  
  if [ -n "${DEB_EXTRAPACKAGES}" ]; then
    echo "           Extra Packages : ${DEB_EXTRAPACKAGES}"
  fi
  if [ -n "${DPKG_RECONFIG}" ]; then
    echo "    Reconfigured Packages : ${DPKG_RECONFIG}"
  fi
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
    gitClone
    echoStage 3 "Building U-Boot"
    buildUBoot
    echoStage 4 "Building Kernel"
    buildKernel
    echoStage 5 "Building Tools"
    buildTools
    echoStage 6 "Installing BootStrap and Packages"
    downloadSys
    installBaseSys
    cleanupSys
    echoStage 7 "Installing Kernel"
    installKernel
    echoStage 8 "Configuring Kernel Modules"
    configModules
    echoStage 9 "Configuring U-Boot"
    installUBoot
    echoStage 10 "Configuring Networking"
    configNetwork
    echoStage 11 "Formatting SD Card"
    formatSD
    echoStage 12 "Transfering Debian to SD Card"
    installSD  
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

show_menu(){
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"`
    ENTER_LINE=`echo "\033[33m"`
    echo "${MENU}    Debian Builder ${SCRIPT_VERSION}     ${NORMAL}"
    echo "${MENU}${NUMBER} 1)${MENU} Setup enviroment ${NORMAL}"
    echo "${MENU}${NUMBER} 2)${MENU} Download or Update Linux source ${NORMAL}"
    echo "${MENU}${NUMBER} 3)${MENU} Build tools ${NORMAL}"
    echo "${MENU}${NUMBER} 4)${MENU} Build Linux kernel ${NORMAL}"
    echo "${MENU}${NUMBER} 5)${MENU} Download rootfs ${NORMAL}"
    echo "${MENU}${NUMBER} 6)${MENU} Install base system ${NORMAL}"
    echo "${MENU}${NUMBER} 7)${MENU} Install modules ${NORMAL}"
    echo ""
    echo "${ENTER_LINE}Please enter the option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    if [ ! -z "$1" ]
    then
        echo $1;
    fi
    read opt
}
option_picked(){
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo "${COLOR}${MESSAGE}${RESET}"
}

clear
show_menu
while [ ! -z "$opt" ]
do
    if [ -z "$opt" ]
    then
        exit;
    else
        case $opt in
        1) clear;
            option_picked "Set up your enviroment";
            if promptyn "Install essential building tools to `uname -v`?"; then
                setupTools
            fi
            option_picked "Done";
            show_menu
            ;;
        2) clear;
            option_picked "Clone repository uBoot,kernel,tools,boards from github";
            gitClone
            if promptyn "Do you want update these repositories?"; then
                git submodule foreach git pull
            fi
            option_picked "Done";
            show_menu
            ;;
        3) clear;
            option_picked "Start build uBoot";
            buildUBoot
            option_picked "Done";
            option_picked "Start build sunxi-tools";
            buildTools
            option_picked "Done";
            show_menu
            ;;
        4) clear;
            option_picked "Build Linux kernel";
            if promptyn "Reconfigure kernel?"; then
                make -C ./linux-sunxi/ ARCH=arm menuconfig
            fi
            make -j4 -C ./linux-sunxi/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
            option_picked "Done";
            show_menu
            ;;
        5) clear;
            option_picked "Download rootfs";
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
                   option_picked "Restore from rootfs";
                   tar -xzvf ${ROOTFS_BACKUP}
                   option_picked "Done";
                   show_menu
                   continue
               fi
            fi
            if promptyn "Download rootfs, it may take a few minutes, continue?"; then
                option_picked "Start download rootfs";
                downloadSys
                option_picked "Make a backup of the clean rootfs";
                if [ -f ${ROOTFS_BACKUP} ];then
                    rm ${ROOTFS_BACKUP}
                fi
                tar -czf ${ROOTFS_BACKUP} ${ROOTFS_DIR}
            fi
            option_picked "Done";
            show_menu
            ;;
        6) clear;
            option_picked "Install base system";
            if [ -f ${BASESYS_BACKUP} ];then
               if promptyn "Found a backup of base system, restore from it?"; then
                   if [ -d ${ROOTFS_DIR} ];then
                       rm -rf ${ROOTFS_DIR}
                   fi
                   option_picked "Restore basesystem, please wait";
                   tar -xzf ${BASESYS_BACKUP}
                   option_picked "Base System Restored";
                   show_menu
                   continue
               fi
            fi
            if [ -d ${ROOTFS_DIR} ];then
                if promptyn "Are you sure to install the base system?"; then
                   option_picked "Installing base system, it may take a while";
                   installBaseSys
                   option_picked "Base system installed";
                fi
                option_picked "Make a backup of the clean base system";
                if [ -f ${BASESYS_BACKUP} ];then
                    rm ${BASESYS_BACKUP}
                fi
                tar -czf ${BASESYS_BACKUP} ${ROOTFS_DIR}
            else
                echo "Stop config rootfs, rootfs is not existed at ${ROOTFS_DIR}"
            fi
            option_picked "Done";
            show_menu
            ;;
        7) clear;
            option_picked "Install modules";
            option_picked "Install UBoot";
                installUBoot
            option_picked "Install linux kernel";
                installKernel
            option_picked "Config Network";
                configNetwork
            option_picked "Config Modules";
                configModules
            option_picked "Done";
            show_menu
            ;;
        *) clear;
            show_menu "$opt is invalid. please enter a number from menu."
            ;;
        esac
    fi
done

