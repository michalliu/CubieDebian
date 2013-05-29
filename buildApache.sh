#!/bin/sh
echo "http://stackoverflow.com/questions/8188158/building-and-configuring-apr-util-and-httpd-to-use-apr-iconv-on-linux"
echo "http://httpd.apache.org/docs/2.2/install.html"
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
if promptyn "yes?";then
echo "y"
fi
