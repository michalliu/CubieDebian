#!/bin/sh
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

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

APR_DIR="${CWD}/APR"
APR_PREFIX="/usr/local/apr-httpd/"
APR_CONFIGURATION="--prefix=${APR_PREFIX}"
APR_CONFIGURE="${APR_DIR}/configure"

if promptyn "build and install apr?";then
    if promptyn "configure apr?";then
        echo "executing $APR_CONFIGURE $APR_CONFIGURATION"
        $APR_CONFIGURE $APR_CONFIGURATION
        if promptyn "make apr?";then
            make -C $APR_DIR
        fi
    fi
fi
