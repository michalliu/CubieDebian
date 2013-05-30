#!/bin/bash
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

haspackage(){
if [ -n $1 ];then
    dpkg -s $1>/dev/null 2>&1
    if [ $? -eq 0 ];then
        return 0
    fi
fi
return 1
}

installpackages(){
  pkglist=( "$@" )
  for pkg in "${pkglist[@]}";do
      if ! haspackage "$pkg";then
          echo "install missing package ${pkg}"
          apt-get install -y "${pkg}"
      fi
  done
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

isRoot() {
  if [ "`id -u`" -ne "0" ]; then
    echo "this script needs to be run as root, try again with sudo"
    return 1
  fi
  return 0
}

isRoot2(){
if [[ ${EUID} != 0 && ${UID} != 0 ]];then
    return 1
fi
return 0
}
