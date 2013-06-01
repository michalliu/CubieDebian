#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh

CONFIGURE="./configure"

PHP5_DIR="${CWD}/php5"
PHP5_CONFIGURATION=" \
--prefix=/opt/php/5.4.15 \
--with-zlib-dir \
--with-freetype-dir \
--enable-cgi \
--enable-mbstring \
--with-libxml-dir=/usr \
--enable-soap \
--enable-calendar \
--with-curl \
--with-mcrypt \
--with-zlib \
--with-gd \
--disable-rpath \
--enable-inline-optimization \
--with-bz2 \
--with-zlib \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-pcntl \
--enable-mbregex \
--with-mhash \
--enable-zip \
--with-pcre-regex \
--with-mysql \
--with-pdo-mysql \
--with-mysqli \
--with-jpeg-dir=/usr \
--with-png-dir=/usr \
--enable-gd-native-ttf \
--with-openssl \
--with-libdir=lib64 \
--with-libxml-dir=/usr \
--enable-exif \
--enable-dba \
--with-gettext \
--enable-shmop \
--enable-sysvmsg \
--enable-wddx \
--with-imap \
--with-imap-ssl \
--with-kerberos \
--enable-bcmath \
--enable-ftp \
--enable-intl \
--with-pspell"

if promptyn "process php5?";then
    cd $PHP5_DIR
    installpackages "libxml2-dev" "re2c" "bison" "libssl-dev"
    if promptyn "configure php5?";then
        echo "configure php5 with configuration $PHP5_CONFIGURATION"
        $CONFIGURE -q $PHP5_CONFIGURATION
    fi
    if promptyn "make php5?";then
        make -C $PHP5_DIR
    fi
    if promptyn "install php5?";then
        make -C $PHP5_DIR install
    fi
fi
