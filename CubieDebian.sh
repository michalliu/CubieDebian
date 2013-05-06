#!/bin/sh

#################
# CONFIGURATION #
#################
# This is the script verion
SCRIPT_VERSION="1.0"

# This will be the hostname of the cubieboard
DEB_HOSTNAME="argon"

# Release name
RELEASE_NAME="${DEB_HOSTNAME}-server"

# Not all packages can be install this way.
# DEB_EXTRAPACKAGES="nvi locales ntp ssh expect"
# Currently ntp module triggers an error when install
DEB_WIRELESS_TOOLS="wireless-tools wpasupplicant"
DEB_TEXT_EDITORS="nvi vim"
DEB_TEXT_UTILITIES="locales ssh expect sudo"
DEB_EXTRAPACKAGES="${DEB_TEXT_EDITORS} ${DEB_TEXT_UTILITIES} ${DEB_WIRELESS_TOOLS}" 

# Not all packages can (or should be) reconfigured this way.
DPKG_RECONFIG="locales tzdata"

# Make sure this is valid and is really your SD..
SD_PATH="/dev/sdb"

# SD Card mount point
SD_MNT_POINT="`pwd`/mnt"

# MAC will be encoded in script.bin
#MAC_ADDRESS="0DEADBEEFBAD"
MAC_ADDRESS="008010EDDF01"

# If you want to use DHCP, use the following
ETH0_MODE="dhcp"

# Rootfs Dir
ROOTFS_DIR="`pwd`/rootfs/${DEB_HOSTNAME}-armfs"

# Rootfs backup
ROOTFS_BACKUP="${DEB_HOSTNAME}.rootfs.cleanbackup.tar.gz"

# Base system backup
BASESYS_BACKUP="${DEB_HOSTNAME}.basesys.cleanbackup.tar.gz"

# Base system has package backup
BASESYS_PKG_BACKUP="${DEB_HOSTNAME}.basesys.pkg.cleanbackup.tar.gz"

# Wireless configuration
WIRELESS_SSID="TP-LINK_3300B6"
WIRELESS_PSK="m i a n x i e"
WIRELESS_IF="wlan0"

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
if [ ! -d "`pwd`/u-boot-sunxi" ];then
git clone https://github.com/linux-sunxi/u-boot-sunxi.git
fi
if [ ! -d "`pwd`/linux-sunxi" ];then
git clone https://github.com/linux-sunxi/linux-sunxi.git -b sunxi-3.4
fi
if [ ! -d "`pwd`/sunxi-tools" ];then
git clone https://github.com/linux-sunxi/sunxi-tools.git
fi
if [ ! -d "`pwd`/sunxi-boards" ];then
git clone https://github.com/linux-sunxi/sunxi-boards.git
fi
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

cleanupEnv() {
rm -f ${ROOTFS_DIR}/usr/bin/qemu-arm-static
rm -f ${ROOTFS_DIR}/etc/resolv.conf
}

prepareEnv() {
# install qemu
if [ ! -f ${ROOTFS_DIR}/usr/bin/qemu-arm-static ];then
    cp -f /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin
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
#debootstrap --foreign --arch armhf wheezy ${ROOTFS_DIR}/ http://mirrors.sohu.com/debian/
debootstrap --foreign --arch armhf wheezy ${ROOTFS_DIR}/ http://http.debian.net/debian/
}

installBaseSys(){
prepareEnv
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

cleanupEnv
}

installPackages(){
prepareEnv
# install extra modules
if [ -n "${DEB_EXTRAPACKAGES}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} apt-get install ${DEB_EXTRAPACKAGES}
fi
cleanupEnv
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

# overlock memory
sed -i 's/^dram_clk = 480$/dram_clk = 500/' ${ROOTFS_DIR}/boot/cubieboard.fex

./sunxi-tools/fex2bin ${ROOTFS_DIR}/boot/cubieboard.fex ${ROOTFS_DIR}/boot/script.bin
}

installKernel() {
cp ./linux-sunxi/arch/arm/boot/uImage ${ROOTFS_DIR}/boot
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

configSys(){
prepareEnv

# prompt to config local and timezone
if promptyn "Configure locale and timezone data?"; then
    if [ -n "${DPKG_RECONFIG}" ]; then
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} dpkg-reconfigure ${DPKG_RECONFIG}
    fi
fi
# backup inittab
if [ ! -f ${ROOTFS_DIR}/etc/inittab.bak ];then
    cp ${ROOTFS_DIR}/etc/inittab ${ROOTFS_DIR}/etc/inittab.bak
fi

# restore inittab from backup
cp ${ROOTFS_DIR}/etc/inittab.bak ${ROOTFS_DIR}/etc/inittab

# add initab content
echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> ${ROOTFS_DIR}/etc/inittab

# backup fstab
if [ ! -f ${ROOTFS_DIR}/etc/fstab.bak ];then
    cp ${ROOTFS_DIR}/etc/fstab ${ROOTFS_DIR}/etc/fstab.bak
fi

# restore fstab from backup
cp ${ROOTFS_DIR}/etc/fstab.bak ${ROOTFS_DIR}/etc/fstab

# add fstab content
cat >> ${ROOTFS_DIR}/etc/fstab <<END
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext4	defaults	0	1
END

# backup modules
if [ ! -f ${ROOTFS_DIR}/etc/modules.bak ];then
    cp ${ROOTFS_DIR}/etc/modules ${ROOTFS_DIR}/etc/modules.bak
fi

# restore modules from backup
cp ${ROOTFS_DIR}/etc/modules.bak ${ROOTFS_DIR}/etc/modules

# backup hosts
if [ ! -f ${ROOTFS_DIR}/etc/hosts.bak ];then
    cp ${ROOTFS_DIR}/etc/hosts ${ROOTFS_DIR}/etc/hosts.bak
fi

# restore hosts from backup
cp ${ROOTFS_DIR}/etc/hosts.bak ${ROOTFS_DIR}/etc/hosts

# add hosts content
cat >> ${ROOTFS_DIR}/etc/hosts <<END
127.0.0.1 ${DEB_HOSTNAME}
END

# add modules content
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

# config accounts
cat > ${ROOTFS_DIR}/tmp/adduser.sh <<END
#!/bin/bash
# add default user
if [ -z "\$(getent passwd ${DEFAULT_USERNAME})" ];then
    useradd -m -s /bin/bash ${DEFAULT_USERNAME}
fi

# set user
echo "${DEFAULT_USERNAME}:${DEFAULT_PASSWD}"|chpasswd

# disable root user
passwd -l root

# prohibit root user ssh
sed -i 's/^PermitRootLogin yes$/PermitRootLogin no/' /etc/ssh/sshd_config

# allow the default user has su privileges
cat > /etc/sudoers.d/sudousers <<DNE
${DEFAULT_USERNAME} ALL=(ALL) NOPASSWD:ALL # Admins can do anthing w/o a password
%cubie ALL=(ALL) NOPASSWD:ALL # Cubie group can do anthing w/o a password
DNE
chmod 0440 /etc/sudoers.d/sudousers
END
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} chmod +x /tmp/adduser.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} /tmp/adduser.sh
LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} rm /tmp/adduser.sh
cleanupEnv
}

installPersonalStuff(){
prepareEnv

# prevent double add content
if [ ! -f ${ROOTFS_DIR}/etc/modules.2.bak ];then
    cp ${ROOTFS_DIR}/etc/modules ${ROOTFS_DIR}/etc/modules.2.bak
fi
cp ${ROOTFS_DIR}/etc/modules.2.bak ${ROOTFS_DIR}/etc/modules

# prevent double add content
if [ ! -f ${ROOTFS_DIR}/etc/network/interfaces.2.bak ];then
    cp ${ROOTFS_DIR}/etc/network/interfaces ${ROOTFS_DIR}/etc/network/interfaces.2.bak
fi
cp ${ROOTFS_DIR}/etc/network/interfaces.2.bak ${ROOTFS_DIR}/etc/network/interfaces

# auto load 8188eu
cat >> ${ROOTFS_DIR}/etc/modules <<END
8188eu
END

# auto startup wireless
if [ -n "${WIRELESS_SSID}" ] && [ -n "${WIRELESS_PSK}" ]; then
    WIRLESS_CONF="/etc/${WIRELESS_SSID}.conf"
    LC_ALL=C LANGUAGE=C LANG=C chroot ${ROOTFS_DIR} wpa_passphrase ${WIRELESS_SSID} "${WIRELESS_PSK}">${ROOTFS_DIR}${WIRLESS_CONF}
    cat >> ${ROOTFS_DIR}/etc/network/interfaces <<END
up wpa_supplicant -Dwext -iwlan0 -c${WIRLESS_CONF} -B
down killall wpa_supplicant
auto ${WIRELESS_IF}
iface ${WIRELESS_IF} inet dhcp
END
fi

cleanupEnv
}

umountSDSafe() {
sync
for n in ${SD_PATH}*;do
    if [ "${SD_PATH}" != "$n" ];then
        if mount|grep ${n};then
            echo "umounting ${n}"
            umount $n
            sleep 1
        fi
    fi
done
}

mountSD() {
umountSDSafe
if [ ! -d ${SD_MNT_POINT} ];then
    mkdir ${SD_MNT_POINT}
fi
mount ${SD_PATH}1 ${SD_MNT_POINT}
}

removeSD() {
if [ -b ${SD_PATH} ];then
eject ${SD_PATH}
else
echo "device ${SD_PATH} doesn't exists"
fi
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
mountSD
cd ${ROOTFS_DIR}
tar -cf - . | tar -C ${SD_MNT_POINT} -xf -
cd ..
umountSDSafe
removeSD
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
    cleanupEnv
    echoStage 7 "Installing Kernel"
    installKernel
    echoStage 8 "Configuring U-Boot"
    installUBoot
    echoStage 9 "Configuring Networking"
    configNetwork
    echoStage 10 "Formatting SD Card"
    formatSD
    echoStage 11 "Transfering Debian to SD Card"
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
    echo "${MENU}${NUMBER} 7)${MENU} Install packages ${NORMAL}"
    echo "${MENU}${NUMBER} 8)${MENU} Install Boot & kernel & config system ${NORMAL}"
    echo "${MENU}${NUMBER} 9)${MENU} Install personal stuff ${NORMAL}"
    echo "${MENU}${NUMBER} 10)${MENU} Install to device ${NORMAL}"
    echo ""
    echo "${NORMAL}    Test Commands (Use them only if you know what you are doing)${NORMAL}"
    echo ""
    echo "${MENU}${NUMBER} 11)${MENU} recompile cubieboard.fex to script.bin on ${SD_PATH}1 /boot ${NORMAL}"
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
                   tar -xzPf ${ROOTFS_BACKUP}
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
                tar -czPf ${ROOTFS_BACKUP} ${ROOTFS_DIR}
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
                   tar -xzPf ${BASESYS_BACKUP}
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
                tar -czPf ${BASESYS_BACKUP} ${ROOTFS_DIR}
            else
                echo "Stop config rootfs, rootfs is not existed at ${ROOTFS_DIR}"
            fi
            option_picked "Done";
            show_menu
            ;;
        7) clear;
            option_picked "Install packages";
            if [ -f ${BASESYS_PKG_BACKUP} ];then
               if promptyn "Found a backup of base system with packages, restore from it?"; then
                   if [ -d ${ROOTFS_DIR} ];then
                       rm -rf ${ROOTFS_DIR}
                   fi
                   option_picked "Restore basesystem with packages, please wait";
                   tar -xzPf ${BASESYS_PKG_BACKUP}
                   option_picked "Base System with packages Restored";
                   show_menu
                   continue
               fi
            fi
            if [ -d ${ROOTFS_DIR} ];then
                option_picked "${DEB_EXTRAPACKAGES}";
                installPackages
                option_picked "Package ${DEB_EXTRAPACKAGES} installed to the system";
                option_picked "Make a backup of the system";
                if [ -f ${BASESYS_PKG_BACKUP} ];then
                    rm ${BASESYS_PKG_BACKUP}
                fi
                tar -czPf ${BASESYS_PKG_BACKUP} ${ROOTFS_DIR}
            else
                echo "Stop config rootfs, rootfs is not existed at ${ROOTFS_DIR}"
            fi
            option_picked "Done";
            show_menu
            ;;
        8) clear;
            option_picked "Install modules"
            option_picked "Install UBoot";
            if [ -f "${ROOTFS_DIR}/boot/boot.scr" ] && [ -f "${ROOTFS_DIR}/boot/script.bin" ];then
                if promptyn "UBoot has been installed, reinstall?"; then
                    installUBoot
                fi
            else
                installUBoot
            fi
            option_picked "Done";
            option_picked "Install linux kernel";
            if [ -f "${ROOTFS_DIR}/boot/uImage" ];then
                if promptyn "Kernel has been installed, reinstall?"; then
                    installKernel
                fi
            else
                installKernel
            fi
            option_picked "Done";
            option_picked "Config Network";
                configNetwork
            option_picked "Done";
            option_picked "Config System";
                configSys
            option_picked "Done";
            show_menu
            ;;
        9) clear;
            option_picked "Install personal stuff"
            installPersonalStuff
            option_picked "Done";
            show_menu
            ;;
        10) clear;
            option_picked "Install to your device ${SD_PATH}"
            option_picked "Device info"
            fdisk -l | grep ${SD_PATH}
            if promptyn "All the data on ${SD_PATH} will be destoried, continue?"; then
                option_picked "umount ${SD_PATH}"
                umountSDSafe
                option_picked "Done";
                option_picked "Formating"
                formatSD
                option_picked "Done";
                option_picked "Transferring data, it may take a while, please be patient, DO NOT UNPLUG YOUR DEVICE, it will be removed automaticlly when finished";
                installSD
                option_picked "Done";
                option_picked "Congratulations,you can safely remove your sd card and enjoy your ${RELEASE_NAME}";
                option_picked "Now press Enter to quit the program";
            fi
            show_menu
            ;;
        11) clear;
            option_picked "recompile cubieboard.fex to script.bin on ${SD_PATH}1 /boot ${NORMAL}"
            umountSDSafe
            sleep 1
            mountSD
            if promptyn "start recompile?"; then
                SD_BOOT_DIR="${SD_MNT_POINT}/boot"
                SD_FEX_FILE="${SD_BOOT_DIR}/cubieboard.fex"
                SD_SCRIPT_BIN_FILE="${SD_BOOT_DIR}/script.bin"

                if [ -f ${SD_FEX_FILE} ];then
                    option_picked "hash `md5sum ${SD_SCRIPT_BIN_FILE}`"
                else
                    option_picked "[W] script.bin not founded"
                fi

                # recompile cubieboard.fex to script.bin
                ./sunxi-tools/fex2bin ${SD_FEX_FILE} ${SD_SCRIPT_BIN_FILE}
                option_picked "hash `md5sum ${SD_SCRIPT_BIN_FILE}`"
                option_picked "Done"
            fi
            if promptyn "remove ${SD_PATH}?"; then
                umountSDSafe
                sleep 1
                removeSD
                option_picked "Your disk removed"
            fi
            show_menu
            ;;
        *) clear;
            show_menu "$opt is invalid. please enter a number from menu."
            ;;
        esac
    fi
done
