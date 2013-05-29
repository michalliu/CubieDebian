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

CONFIGURE="./configure"
PREFIX_BASE="/usr/local"

APR_DIR="${CWD}/APR"
APR_PREFIX="${PREFIX_BASE}/apr-httpd/"
APR_CONFIGURATION="--prefix=${APR_PREFIX}"

PCRE_DIR="${CWD}/PCRE"
PCRE_PREFIX="${PREFIX_BASE}/pcre"
PCRE_CONFIGURATION="--prefix=${PCRE_PREFIX}"

OPENSSL_DIR="${CWD}/openssl"
OPENSSL_PREFIX="${PREFIX_BASE}"
OPENSSL_CONFIGURATION="--prefix=${OPENSSL_PREFIX} \
--openssldir=${OPENSSL_PREFIX}/openssl"

APR_UTIL_DIR="${CWD}/APR-util"
APR_UTIL_PREFIX="${PREFIX_BASE}/apr-util-httpd/"
APR_UTIL_CONFIGURATION="--prefix=${APR_UTIL_PREFIX} \
--with-crypto \
--with-openssl=/usr/local/include \
--with-apr=${APR_PREFIX} \
--with-ldap-lib=/usr/lib \
--with-ldap=ldap \
--with-apr-iconv=../APR-iconv"

HTTPD_DIR="${CWD}/httpd"
HTTPD_CONFIGURATION="--enable-authn-anon \
--enable-v4-mapped \
--enable-authz-owner \
--enable-auth-digest \
--disable-imagemap \
--enable-cgi \
--enable-dav \
--enable-dav-fs \
--enable-dav-lock \
--enable-deflate \
--enable-expires \
--enable-headers \
--enable-info \
--enable-mime-magic \
--enable-proxy \
--enable-proxy-ajp \
--enable-proxy-http \
--enable-proxy-ftp \
--enable-proxy-balancer \
--enable-proxy-connect \
--enable-rewrite \
--enable-suexec \
--enable-ssl \
--enable-so \
--enable-ssl \
--enable-static-rotatelogs \
--enable-speling
--disable-userdir \
--enable-vhost-alias \
--with-mpm=prefork \
--enable-mods-shared=all \
--with-pcre=${PCRE_PREFIX} \
--with-ssl=${OPENSSL_PREFIX}/openssl \
--with-apr=${APR_PREFIX}bin/apr-1-config \
--with-apr-util=${APR_UTIL_PREFIX}bin/apu-1-config"

if promptyn "process apr?";then
    cd $APR_DIR
    if promptyn "configure apr?";then
        echo "configure apr with configuration $APR_CONFIGURATION"
        $CONFIGURE -q $APR_CONFIGURATION
    fi
    if promptyn "make apr?";then
        make -C $APR_DIR
    fi
    if promptyn "install apr?";then
        make -C $APR_DIR install
    fi
fi

if promptyn "process PCRE?";then
    cd $PCRE_DIR
    if promptyn "configure PCRE?";then
        echo "configure PCRE with configuration $PCRE_CONFIGURATION"
        $CONFIGURE -q $PCRE_CONFIGURATION
    fi
    if promptyn "make PCRE?";then
        make -C $PCRE_DIR
    fi
    if promptyn "install PCRE?";then
        make -C $PCRE_DIR install
    fi
fi

if promptyn "process openssl?";then
    cd $OPENSSL_DIR
    if promptyn "configure openssl?";then
        echo "configure openssl with configuration $OPENSSL_CONFIGURATION"
        ./config $OPENSSL_CONFIGURATION
    fi
    if promptyn "make openssl?";then
        make -C $OPENSSL_DIR
    fi
    if promptyn "install openssl?";then
        make -C $OPENSSL_DIR install
    fi
fi


if promptyn "process apr-util?";then
    apt-get install libldap-dev
    cd $APR_UTIL_DIR
    if promptyn "configure apr-util?";then
        echo "configure apr with configuration $APR_UTIL_CONFIGURATION"
        $CONFIGURE -q $APR_UTIL_CONFIGURATION
    fi
    if promptyn "make apr-util?";then
        make -C $APR_UTIL_DIR
    fi
    if promptyn "install apr-util?";then
        make -C $APR_UTIL_DIR install
    fi
fi

if promptyn "process httpd?";then
    apt-get install zlib1g-dev
    apt-get install lua5.1
    cd $HTTPD_DIR
    if promptyn "configure httpd?";then
        echo "configure httpd with configuration $HTTPD_CONFIGURATION"
        $CONFIGURE -q $HTTPD_CONFIGURATION
    fi
    if promptyn "make httpd?";then
        make -C $HTTPD_DIR
    fi
    if promptyn "install httpd?";then
        make -C $HTTPD_DIR install
    fi
fi
