#!/bin/bash

local choice

#Key Codes
ARROWUP='\[A'
ARROWDOWN='\[B'
ARROWRIGHT='\[C'
ARROWDOWN='\[D'
INSERT='\[2'
DELETE='\[3'



#Text Colors - Accent type
BOLD='\033[1m'
DBOLD='\033[2m'
NBOLD='\033[22m'
UNDERLINE='\033[4m'
NUNDERLINE='\033[4m'
BLINK='\033[5m'
NBLINK='\033[5m'
INVERSE='\033[7m'
NINVERSE='\033[7m'
BREAK='\033[m'
NORMAL='\033[0m'

#Text Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'

#Text Colors - Brighter versions
DGRAY='\033[1;30m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LYELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LMAGENTA='\033[1;35m'
LCYAN='\033[1;36m'
WHITE='\033[1;37m'

#Text Colors - Background colors
BGBLACK='\033[40m'
BGRED='\033[41m'
BGGREEN='\033[42m'
BGBROWN='\033[43m'
BGBLUE='\033[44m'
BGMAGENTA='\033[45m'
BGCYAN='\033[46m'
BGGRAY='\033[47m'
BGDEF='\033[49m'

#Text Colors - Reset to default
RESET='\033[0;0;39m'

sdcard_partition1=1
sdcard_partition2=2
sdcard_partition3=3

if [[ $1 == "" ]] ; then 
	sdcard_dev_id=$(ls -I "*part*" /dev/disk/by-id/ | grep usb)
	sdcard_dev_path=$(readlink -e /dev/disk/by-id/${sdcard_dev_id})
	sdcard_partition1=1
	sdcard_partition2=2
	sdcard_partition3=3
	clear
	echo -e "${LGREEN}======== Greenvity's SD card preparation script for i.MX287 ========"
	echo -e ""
	echo -e "${RESET}Autodetected SD Card path as ${LRED}${sdcard_dev_path}"
	echo -e "${RESET}Card reader is ${LYELLOW}${sdcard_dev_id}\n"
	echo -e "    ${RESET}If you want to write to a different device,"
	echo -e "    please pass that as command line argument"
	echo -e "    e.g. ${0} /dev/sdb"
	echo -e "${LGREEN}____________________________________________________________________${RESET}"

	read -p "Do you want to continue? (Y/N)" choice

	if [[ $choice != y && $choice != Y ]] ; then
		exit 0
	fi 
else
	sdcard_dev_path=$1
	clear
	echo -e "${LGREEN}======== Greenvity's SD card preparation script for i.MX287 ========"
	echo -e ""
	echo -e "${RESET}Manually specified SD Card path as ${LRED}${sdcard_dev_path}"
	echo -e "${LGREEN}____________________________________________________________________${RESET}"

	read -p "Do you want to continue? (Y/N)" choice

	if [[ $choice != y && $choice != Y ]] ; then
		exit 0
	fi
fi

echo -e "${LCYAN}Phase 1/4 Partitioning SD Card...${LMAGENTA}"
sudo umount ${sdcard_dev_path}${sdcard_partition1}
sudo umount ${sdcard_dev_path}${sdcard_partition2}
sudo umount ${sdcard_dev_path}${sdcard_partition3}
sudo fdisk ${sdcard_dev_path} <<EOF
d
1
d
2
d
n
p
1

+1M
n
p
2

+8M
n
p
3


t
2
53
a
1
w
EOF
$(sync)

echo -e "${LCYAN}Phase 2/4 Writing Bootloader to second partition (${sdcard_dev_path}${sdcard_partition2})...${LMAGENTA}"
$(sudo ./sdimage -f imx28_bootimage.sb -d ${sdcard_dev_path})
$(sync)

echo -e "${LCYAN}Phase 3/4 Formatting third partition for rootfs (${sdcard_dev_path}${sdcard_partition3})...${LMAGENTA}"
$(sudo mkfs.ext4 ${sdcard_dev_path}${sdcard_partition3})
$(sync)

echo -e "${LCYAN}Phase 4/4 Copying rootfs...${LMAGENTA}"
$(sudo mkdir -p /mnt/mmc)
$(sudo mount ${sdcard_dev_path}${sdcard_partition3} /mnt/mmc)
$(sudo tar -jxf rootfs.tar.bz2 -C /mnt/mmc)
$(sync)
$(sudo umount /mnt/mmc)

echo -e "${LCYAN}SD card has been prepared, quitting...${RESET}"
