#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)
ttyUSB="/dev/ttyUSB"

ports=();

isRoot() {
  if [ "`id -u`" -ne "0" ]; then
    echo "This script needs to be run as root, try again with sudo"
    return 1
  fi
  return 0
}

for port in $ttyUSB*;do
ports+=("$port")
done

show_menu(){
    NORMAL=`echo -e "\033[m"`
    MENU=`echo -e "\033[36m"` #Blue
    NUMBER=`echo -e "\033[33m"` #yellow
    FGRED=`echo -e "\033[41m"`
    RED_TEXT=`echo -e "\033[31m"`
    ENTER_LINE=`echo -e "\033[33m"`

    echo "${NORMAL}    Select Port${NORMAL}"

    for i in "${!ports[@]}";do
    echo "${MENU}${NUMBER} "$i")${MENU} ${ports[0]} ${NORMAL}"
    done

    echo "${ENTER_LINE}Please enter the option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    if [ ! -z "$1" ]
    then
        echo $1;
    fi
    read opt
}

if ! isRoot;then
  exit
fi

clear
show_menu
while [ ! -z "$opt" ];do
  screen ${ports[$opt]} 115200
  exit
done
