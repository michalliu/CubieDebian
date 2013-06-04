#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh

CONFIGURE="./configure"

PHP5_ALIAS="php54"

PHP5_SRC_DIR="${CWD}/php5"
PHP5_CONFIGURATION=" \
--with-layout=GNU \
--with-libdir=lib64 \
--disable-debug \
--with-regex=php \
--disable-rpath \
--disable-static \
--disable-posix \
--with-pic \
--without-pear \
--enable-calendar \
--enable-sysvsem \
--enable-sysvshm \
--enable-sysvmsg \
--enable-bcmath \
--with-bz2 \
--enable-ctype \
--with-db4 \
--without-gdbm \
--with-iconv \
--enable-exif \
--enable-ftp \
--enable-cli \
--with-gettext \
--enable-mbstring \
--with-pcre-regex=/usr \
--enable-shmop \
--enable-sockets \
--enable-wddx \
--with-libxml-dir=/usr \
--with-zlib \
--with-kerberos=/usr \
--with-openssl=/usr \
--enable-soap \
--enable-zip \
--with-mhash \
--without-mm \
--with-curl=shared,/usr \
--with-zlib-dir=/usr \
--with-vpx-dir=/usr \
--with-gd \
--enable-gd-native-ttf \
--with-gmp=shared,/usr \
--with-jpeg-dir=shared,/usr \
--with-xpm-dir=shared,/usr/X11R6 \
--with-png-dir=shared,/usr \
--with-freetype-dir=shared,/usr \
--with-ttf=shared,/usr \
--with-t1lib=shared,/usr \
--with-ldap=shared,/usr \
--with-mysql=shared,/usr \
--with-mysqli=shared,/usr/bin/mysql_config \
--with-pgsql=shared,/usr \
--with-pspell=shared,/usr \
--with-unixODBC=shared,/usr \
--with-xsl=shared,/usr \
--with-snmp=shared,/usr \
--with-sqlite=shared,/usr \
--with-tidy=shared,/usr \
--with-xmlrpc=shared \
--enable-pdo=shared \
--without-pdo-dblib \
--with-pdo-mysql=shared,/usr \
--with-pdo-pgsql=shared,/usr \
--with-pdo-odbc=shared,unixODBC,/usr \
--with-pdo-dblib=shared,/usr \
--enable-force-cgi-redirect  --enable-fastcgi \
--with-libdir=/lib/arm-linux-gnueabihf \
--with-pdo-sqlite=shared \
--with-sqlite=shared \
--enable-ipv6 \
--with-mcrypt \
--with-imap-ssl"

if promptyn "process php5?";then
    cd $PHP5_SRC_DIR
    installpackages "libxml2-dev" \
"re2c" \
"bison" \
"libssl-dev" \
"libpcre3-dev" \
"libbz2-dev" \
"libcurl4-openssl-dev" \
"libdb5.1-dev" \
"libjpeg8-dev" \
"libpng12-dev" \
"libxpm-dev" \
"libfreetype6-dev" \
"libmysqlclient-dev" \
"postgresql-server-dev-9.1" \
"libt1-dev" \
"libgd2-xpm-dev" \
"libgmp-dev" \
"libsasl2-dev" \
"libmhash-dev" \
"unixodbc-dev" \
"freetds-dev" \
"libpspell-dev" \
"libsnmp-dev" \
"libtidy-dev" \
"libxslt1-dev" \
"libmcrypt-dev" \
"libvpx-dev"

    if promptyn "configure php5?";then
        echo "configure php5 with configuration $PHP5_CONFIGURATION"
        $CONFIGURE $PHP5_CONFIGURATION
    fi
    if promptyn "make php5?";then
        make -C $PHP5_SRC_DIR
    fi
    if promptyn "install php5?";then
        make -C $PHP5_SRC_DIR install
    fi
fi
