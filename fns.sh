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
  missingpkgs=""
  for pkg in "${pkglist[@]}";do
      if ! haspackage "$pkg";then
          missingpkgs="${missingpkgs} ${pkg}"
      fi
  done
  if [[ -n $missingpkgs ]];then
      echo "Install packages ${missingpkgs}"
      apt-get install -y ${missingpkgs}
  else
      echo "All the deb package were installed"
  fi
}

dependspackages(){
  pkglist=( "$@" )
  missingpkgs=""
  echo "Check whether dependency packages installed $@"
  for pkg in "${pkglist[@]}";do
      if ! haspackage "$pkg";then
          missingpkgs="${missingpkgs} ${pkg}"
          echo "${pkg} isn't installed"
      fi
  done
  if [[ -n $missingpkgs ]];then
      echo "Install the missing dependencies${missingpkgs}"
      apt-get install -y ${missingpkgs}
  else
      echo "Yeeah, all the dependencies were installed"
  fi
}

ismounted(){
if [[ -d $1 ]];then
    currdir=`pwd`
    absdir=$(cd $1;pwd)
    cd $currdir
    if grep -qs "$absdir" /proc/mounts;then
        return 0
    else 
        return 1
    fi
fi
return 2
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
    echo "This script needs to be run as root, try again with sudo"
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

testbz2(){
    echo "Check integrity of file $1"
    bzip2 -t $1>/dev/null 2>&1
    if [ ! $? -eq 0 ];then
        echo "$1 is broken"
        return 1
    fi
    return 0
}

pause(){
    PROMPT_TEXT="Press any key to continue..."
    PROMPT_TIMEOUT=10
    if [[ $1 =~ "^[0-9]+$" ]];then
    PROMPT_TIMEOUT=$1
    fi
    read -t${PROMPT_TIMEOUT} -n1 -p "${PROMPT_TEXT}" key
    return 0
}

echoRed(){
    COLOR=`echo -e "\033[01;31m"` # bold red
    RESET=`echo -e "\033[00;00m"` # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo "${COLOR}${MESSAGE}${RESET}"
}
