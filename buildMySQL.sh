#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh
TOOLCHAIN="${CWD}/toolchain/arm-2010.09"
export PATH=${TOOLCHAIN}/bin:$PATH


