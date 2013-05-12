#!/bin/bash

#this is a short Morse code decoder written as a shellscript using sed
#the Morse coded text should be written with spaces between the letters
#only good to convert from Morse code to text
#by scvalex
DOT=.
morseDecode(){
    # $@
    # ():;=-"
    # .,?'!/
    # digits
    # alpha letters
printf "%s" $1\  | tr $DOT 0 \
    | sed -e {s/000-00-\ /\$/g} -e {s/0--0-0\ /@/g} \
    | sed -e {s/-0--0-\ /\(/g} -e {s/-0--0-\ /\)/g} -e {s/---000\ /:/g} -e {s/-0-0-0\ /\;/g} -e {s/-000-\ /=/g} -e {s/-0000-\ /-/g} -e {s/0-00-0\ /\"/g}\
    | sed -e {s/0-0-0-\ /./g} -e {s/--00--\ /\,/g} -e {s/00--00\ /\?/g} -e {s/0----0\ /\'/g} -e {s/-0-0--\ /!/g} -e {s/-00-0\ /\\//g} \
    | sed -e {s/0----\ /1/g} -e {s/00---\ /2/g} -e {s/000--\ /3/g} -e {s/000-\ /4/g} -e {s/00000\ /5/g} -e {s/-0000\ /6/g} -e {s/--000\ /7/g} -e {s/---00\ /8/g} -e {s/----0\ /9/g} -e {s/-----\ /0/g} \
    | sed -e {s/-0-0\ /c/g} -e {s/-000\ /b/g} -e {s/00-0\ /f/g} -e {s/0000\ /h/g} -e {s/0---\ /j/g} -e {s/0-00\ /l/g} -e {s/0--0\ /p/g} -e {s/--0-\ /q/g} -e {s/000-\ /v/g} -e {s/-00-\ /x/g} -e {s/-0--\ /y/g} -e {s/--00\ /z/g} \
    | sed -e {s/0--\ /w/g} -e {s/-00\ /d/g} -e {s/--0\ /g/g} -e {s/-0-\ /k/g} -e {s/---\ /o/g} -e {s/0-0\ /r/g} -e {s/000\ /s/g} -e {s/00-\ /u/g} \
    | sed -e {s/0-\ /a/g} -e {s/00\ /i/g} -e {s/--\ /m/g} -e {s/-0\ /n/g} \
    | sed -e {s/0\ /e/g} -e {s/-\ /t/g}
}

CODES=($@)
for i in "${CODES[@]}";do
morseDecode $i
done
if [ "$1" != "" ];then
printf "\n"
fi
