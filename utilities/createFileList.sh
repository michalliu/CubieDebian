#!/bin/bash

PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)
ABS_FOLDER=$1

# Convert to absolute path
if [[ $ABS_FOLDER != /* ]];then
ABS_FOLDER="${CWD}/${ABS_FOLDER}"
fi

#echo "Generate file list ${ABS_FOLDER}"
BASE_LEN=$(expr ${#ABS_FOLDER} + 1)

for FILE in $(find ${ABS_FOLDER} -type f); do
	HEADER_FILE=${FILE:$BASE_LEN}
	echo $HEADER_FILE
done
