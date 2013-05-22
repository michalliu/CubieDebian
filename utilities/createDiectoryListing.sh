#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)
FOLDER=$1
ABS_FOLDER="${CWD}/${FOLDER}"

echo "Generate directy list ${ABS_FOLDER}"

for DIR in $(find ${ABS_FOLDER} -type d | grep -v ".git"); do
  echo "enter $DIR"
  RELATIVE_DIR=${DIR/$ABS_FOLDER//}
  #echo $RELATIVE_DIR
  (
    echo -e '<!doctype html>\n<html>\n\t<head>\n\t\t<style>\n  h1 {\n    border-bottom: 1px solid #c0c0c0;\n    margin-bottom: 10px;\n    padding-bottom: 10px;\n    white-space: nowrap;\n  }\n\n  table {\n    border-collapse: collapse;\n  }\n\n  .monospace{\nfont-family:monospace;\n}\ntr.header {\n    font-weight: bold;\n  }\n\n  td.detailsColumn {\n    padding-left: 2em;\n    text-align: right;\n    white-space: nowrap;\n  }\n\n  a.icon {\n    padding-left: 1.5em;\n    text-decoration: none;\n  }\n\n  a.icon:hover {\n    text-decoration: underline;\n  }\n\n  a.file {\n    background : url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAABnRSTlMAAAAAAABupgeRAAABHUlEQVR42o2RMW7DIBiF3498iHRJD5JKHurL+CRVBp+i2T16tTynF2gO0KSb5ZrBBl4HHDBuK/WXACH4eO9/CAAAbdvijzLGNE1TVZXfZuHg6XCAQESAZXbOKaXO57eiKG6ft9PrKQIkCQqFoIiQFBGlFIB5nvM8t9aOX2Nd18oDzjnPgCDpn/BH4zh2XZdlWVmWiUK4IgCBoFMUz9eP6zRN75cLgEQhcmTQIbl72O0f9865qLAAsURAAgKBJKEtgLXWvyjLuFsThCSstb8rBCaAQhDYWgIZ7myM+TUBjDHrHlZcbMYYk34cN0YSLcgS+wL0fe9TXDMbY33fR2AYBvyQ8L0Gk8MwREBrTfKe4TpTzwhArXWi8HI84h/1DfwI5mhxJamFAAAAAElFTkSuQmCC ") left top no-repeat;\n  }\n\n  a.dir {\n    background : url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAd5JREFUeNqMU79rFUEQ/vbuodFEEkzAImBpkUabFP4ldpaJhZXYm/RiZWsv/hkWFglBUyTIgyAIIfgIRjHv3r39MePM7N3LcbxAFvZ2b2bn22/mm3XMjF+HL3YW7q28YSIw8mBKoBihhhgCsoORot9d3/ywg3YowMXwNde/PzGnk2vn6PitrT+/PGeNaecg4+qNY3D43vy16A5wDDd4Aqg/ngmrjl/GoN0U5V1QquHQG3q+TPDVhVwyBffcmQGJmSVfyZk7R3SngI4JKfwDJ2+05zIg8gbiereTZRHhJ5KCMOwDFLjhoBTn2g0ghagfKeIYJDPFyibJVBtTREwq60SpYvh5++PpwatHsxSm9QRLSQpEVSd7/TYJUb49TX7gztpjjEffnoVw66+Ytovs14Yp7HaKmUXeX9rKUoMoLNW3srqI5fWn8JejrVkK0QcrkFLOgS39yoKUQe292WJ1guUHG8K2o8K00oO1BTvXoW4yasclUTgZYJY9aFNfAThX5CZRmczAV52oAPoupHhWRIUUAOoyUIlYVaAa/VbLbyiZUiyFbjQFNwiZQSGl4IDy9sO5Wrty0QLKhdZPxmgGcDo8ejn+c/6eiK9poz15Kw7Dr/vN/z6W7q++091/AQYA5mZ8GYJ9K0AAAAAASUVORK5CYII= ") left top no-repeat;\n  }\n\n  a.up {\n    background : url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAmlJREFUeNpsU0toU0EUPfPysx/tTxuDH9SCWhUDooIbd7oRUUTMouqi2iIoCO6lceHWhegy4EJFinWjrlQUpVm0IIoFpVDEIthm0dpikpf3ZuZ6Z94nrXhhMjM3c8895977BBHB2PznK8WPtDgyWH5q77cPH8PpdXuhpQT4ifR9u5sfJb1bmw6VivahATDrxcRZ2njfoaMv+2j7mLDn93MPiNRMvGbL18L9IpF8h9/TN+EYkMffSiOXJ5+hkD+PdqcLpICWHOHc2CC+LEyA/K+cKQMnlQHJX8wqYG3MAJy88Wa4OLDvEqAEOpJd0LxHIMdHBziowSwVlF8D6QaicK01krw/JynwcKoEwZczewroTvZirlKJs5CqQ5CG8pb57FnJUA0LYCXMX5fibd+p8LWDDemcPZbzQyjvH+Ki1TlIciElA7ghwLKV4kRZstt2sANWRjYTAGzuP2hXZFpJ/GsxgGJ0ox1aoFWsDXyyxqCs26+ydmagFN/rRjymJ1898bzGzmQE0HCZpmk5A0RFIv8Pn0WYPsiu6t/Rsj6PauVTwffTSzGAGZhUG2F06hEc9ibS7OPMNp6ErYFlKavo7MkhmTqCxZ/jwzGA9Hx82H2BZSw1NTN9Gx8ycHkajU/7M+jInsDC7DiaEmo1bNl1AMr9ASFgqVu9MCTIzoGUimXVAnnaN0PdBBDCCYbEtMk6wkpQwIG0sn0PQIUF4GsTwLSIFKNqF6DVrQq+IWVrQDxAYQC/1SsYOI4pOxKZrfifiUSbDUisif7XlpGIPufXd/uvdvZm760M0no1FZcnrzUdjw7au3vu/BVgAFLXeuTxhTXVAAAAAElFTkSuQmCC ") left top no-repeat;\n  }\n\t\t</style>\n\t</head>\n<body>'
    echo -e "<h1 id=\"header\">Index of ${RELATIVE_DIR}</h1>"
    echo -e '<table id="table">\n\t<tbody>\n\t    <tr class="header">\n                <td i18n-content="headerName">File</td>\n                <td class="detailsColumn">Size</td>\n                <td class="detailsColumn">Date Modified</td>\n                <td class="detailsColumn">MD5</td>\n            </tr>\n        </tbody>'
    ls -1pash "${DIR}" --full-time \
        | grep -v "^\./$" \
        | grep -v "index\.html$" \
        | grep -v ".git/$" \
        | awk '{if($1 == "total") {\
#printf "Total	[%s]\n",$2
}\
else if ($10 ~ /^\.\/$/) {\
# current folder
}\
else if ($10 ~ /^\.\.\/$/) {\
# up folder
if (relative_dir ~ /^\/$/) {\
}else{\
printf "\t<tr>\n\t\t<td><a class=\"icon up\" href=\"../index.html\">[parent directory]</a></td>\n\t\t<td class=\"detailsColumn\"></td>\n\t\t<td class=\"detailsColumn\"></td>\n\t\t<td class=\"detailsColumn\"></td>\n\t</tr>\n"\
}\
}\
else if ($10 ~ /\/$/) {\
# directory
printf "\t<tr>\n\t\t<td><a class=\"icon dir\" href=\"%sindex.html\">%s</a></td>\n\t\t<td class=\"detailsColumn\"></td>\n\t\t<td class=\"detailsColumn\">%s %s</td>\n\t\t<td class=\"detailsColumn\"></td>\n\t</tr>\n",$10,$10,$7,substr($8,0,9)\
}\
 else {\
printf "\t<tr>\n\t\t<td><a class=\"icon file\" href=\"%s\">%s</a></td>\n\t\t<td class=\"detailsColumn\">%s</td>\n\t\t<td class=\"detailsColumn\">%s %s</td>\n\t\t<td class=\"detailsColumn monospace\">\nmd5sum %s/%s\n</td>\n\t</tr>\n",$10,$10,$1,$7,substr($8,0,9),dir,$10\
}\
}' dir=$DIR relative_dir=$RELATIVE_DIR
    echo -e '</table>\n</body>\n</html>'
  ) | while read line; do 
    if [[ "$line" =~ "md5sum" ]];then
        HASH=(`eval "$line"`)
        echo ${HASH[0]}
    else
        printf "%s" "$line"
    fi
done > "${DIR}/index.html"
done
