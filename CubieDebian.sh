#!/bin/sh

#################
# CONFIGURATION #
#################

# This will be the hostname of the cubieboard
DEB_HOSTNAME="argon"

# Not all packages can be install this way.
DEB_EXTRAPACKAGES="nvi locales ntp ssh"

# Not all packages can (or should be) reconfigured this way.
DPKG_RECONFIG="locales tzdata"

# Make sure this is valid and is really your SD..
SD_PATH="/dev/sdb"

# MAC will be encoded in script.bin
#MAC_ADDRESS="0DEADBEEFBAD"
MAC_ADDRESS="008010EDDF01"

# If you want to use DHCP, use the following
ETH0_MODE="dhcp"

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
apt-get install build-essential u-boot-tools qemu-user-static debootstrap git binfmt-support libusb-1.0-0-dev pkg-config libncurses5-dev

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
make -C ./linux-sunxi/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
}

buildTools() {
make -C ./sunxi-tools/
}

bootStrap(){
rm -rf ${DEB_HOSTNAME}-armfs
mkdir ${DEB_HOSTNAME}-armfs
debootstrap --foreign --arch armhf wheezy ./${DEB_HOSTNAME}-armfs/
cp /usr/bin/qemu-arm-static ./${DEB_HOSTNAME}-armfs/usr/bin
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ /debootstrap/debootstrap --second-stage
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ dpkg --configure -a
echo ${DEB_HOSTNAME} > ./${DEB_HOSTNAME}-armfs/etc/hostname
cp /etc/resolv.conf ./${DEB_HOSTNAME}-armfs/etc/
echo deb http://http.debian.net/debian/ wheezy main contrib non-free > ./${DEB_HOSTNAME}-armfs/etc/apt/sources.list
echo deb http://security.debian.org/ wheezy/updates main contrib non-free >> ./${DEB_HOSTNAME}-armfs/etc/apt/sources.list
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ apt-get update
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ apt-get upgrade
if [ -n "${DEB_EXTRAPACKAGES}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ apt-get install ${DEB_EXTRAPACKAGES}
fi

if [ -n "${DPKG_RECONFIG}" ]; then
LC_ALL=C LANGUAGE=C LANG=C chroot ./${DEB_HOSTNAME}-armfs/ dpkg-reconfigure ${DPKG_RECONFIG}
fi

echo ""
echo "Please enter a new root password for ${DEB_HOSTNAME}"
chroot ./${DEB_HOSTNAME}-armfs/ passwd 
echo ""

rm ./${DEB_HOSTNAME}-armfs/usr/bin/qemu-arm-static
rm ./${DEB_HOSTNAME}-armfs/etc/resolv.conf
}

installKernel() {
cd ./${DEB_HOSTNAME}-armfs/
cp ../linux-sunxi/arch/arm/boot/uImage boot
make -C ../linux-sunxi INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install
cd ..
}

configModules() {
echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> ./${DEB_HOSTNAME}-armfs/etc/inittab

cat > ./${DEB_HOSTNAME}-armfs/etc/fstab <<END
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext4	defaults	0	1
END

cat >> ./${DEB_HOSTNAME}-armfs/etc/modules <<END

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
}

configUBoot() {
cat > ./${DEB_HOSTNAME}-armfs/boot/boot.cmd <<END
setenv bootargs console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x20p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
END
mkimage -C none -A arm -T script -d ./${DEB_HOSTNAME}-armfs/boot/boot.cmd ./${DEB_HOSTNAME}-armfs/boot/boot.scr

cp ./sunxi-boards/sys_config/a10/cubieboard.fex ./${DEB_HOSTNAME}-armfs/boot/
cat >> ./${DEB_HOSTNAME}-armfs/boot/cubieboard.fex <<END

[dynamic]
MAC = "${MAC_ADDRESS}"
END

./sunxi-tools/fex2bin ./${DEB_HOSTNAME}-armfs/boot/cubieboard.fex ./${DEB_HOSTNAME}-armfs/boot/script.bin
}

configNetwork() {
cat >> ./${DEB_HOSTNAME}-armfs/etc/network/interfaces <<END
auto eth0
allow-hotplug eth0
iface eth0 inet ${ETH0_MODE}
END

if [ "${ETH0_MODE}" != "dhcp" ]; then 
cat >> ./${DEB_HOSTNAME}-armfs/etc/network/interfaces <<END
address ${ETH0_IP}
netmask ${ETH0_MASK}
gateway ${ETH0_GW}
END
cat > ./${DEB_HOSTNAME}-armfs/etc/resolv.conf <<END
search ${DNS_SEARCH}
nameserver ${DNS1}
nameserver ${DNS2}
END
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
mkdir mnt
mount ${SD_PATH}1 ./mnt/
cd ./${DEB_HOSTNAME}-armfs/
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
    bootStrap
    echoStage 7 "Installing Kernel"
    installKernel
    echoStage 8 "Configuring Kernel Modules"
    configModules
    echoStage 9 "Configuring U-Boot"
    configUBoot
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
