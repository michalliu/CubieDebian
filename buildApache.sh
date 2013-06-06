#!/bin/bash
PWD="`pwd`"
CWD=$(cd "$(dirname "$0")"; pwd)

source ${CWD}/fns.sh

CONFIGURE="./configure"
PREFIX_BASE="/usr/local"

APR_SRC_DIR="${CWD}/APR"
APR_PREFIX="${PREFIX_BASE}/apr"
APR_CONFIGURATION="--prefix=${APR_PREFIX}"

PCRE_SRC_DIR="${CWD}/PCRE"
PCRE_PREFIX="${PREFIX_BASE}/pcre"
PCRE_CONFIGURATION="--prefix=${PCRE_PREFIX}"

APR_ICONV_DIR="${CWD}/APR-iconv"
APR_ICONV_PREFIX="${PREFIX_BASE}/apr-iconv"
APR_ICONV_CONFIGURATION=" \
--prefix=${APR_ICONV_PREFIX} \
--with-apr=${APR_PREFIX}/bin/apr-1-config"

APR_UTIL_SRC_DIR="${CWD}/APR-util"
APR_UTIL_PREFIX="${PREFIX_BASE}/apr-util"
APR_UTIL_CONFIGURATION=" \
--prefix=${APR_UTIL_PREFIX} \
--with-crypto \
--with-openssl=/usr/lib \
--with-apr=${APR_PREFIX} \
--with-ldap-lib=/usr/lib \
--with-ldap=ldap \
--with-iconv=${APR_ICONV_PREFIX}"

HTTPD_SRC_DIR="${CWD}/httpd"
HTTPD_CONFIGURATION=" \
--enable-authn-anon \
--enable-authn-dbm \
--enable-authz-owner \
--enable-auth-digest \
--enable-authz-ldap \
--enable-cache \
--enable-charset-lite \
--enable-dav \
--enable-dav-fs \
--enable-dav-lock \
--enable-deflate \
--enable-disk-cache \
--enable-expires \
--enable-ext-filter \
--enable-file-cache \
--enable-headers \
--enable-info \
--enable-ldap \
--enable-logio \
--enable-mem-cache \
--enable-mime-magic \
--enable-isapi \
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
--enable-static-rotatelogs \
--enable-static-ab \
--enable-speling \
--enable-ssl \
--enable-vhost-alias \
--with-mpm=prefork \
--enable-mods-shared=all \
--enable-v4-mapped \
--with-port=8080 \
--with-pcre=${PCRE_PREFIX} \
--with-ssl=/usr/lib \
--with-apr=${APR_PREFIX}/bin/apr-1-config \
--with-apr-util=${APR_UTIL_PREFIX}/bin/apu-1-config"

installTools(){
apache_bin_dir="/usr/local/apache2/bin"
local_ab2="${apache_bin_dir}/ab2"
local_apachectl="${apache_bin_dir}/apachectl"

sys_bin_dir="/usr/bin"
sys_ab="${sys_bin_dir}/ab"
sys_apachectl="${sys_bin_dir}/apachectl"

if [[ ! -f "$local_ab2" ]];then
    cat >"$local_ab2"<<END
#!/bin/bash
set -e
# Disable kernel's SYN flood protection temporarily
sysctl -w net.ipv4.tcp_syncookies=0
"${apache_bin_dir}/ab" \$@
# Enable kernel's SYN flood protection
sysctl -w net.ipv4.tcp_syncookies=1
END
fi

chmod 0755 "$local_ab2"

if [[ ! -f "$sys_ab" ]];then
ln -s $local_ab2 $sys_ab
fi

if [[ ! -f "$sys_apachectl" ]];then
ln -s $local_apachectl $sys_apachectl
fi
}

configApache(){
defaultenabledmodules=("mod_mime" "mod_rewrite")
defaultenabledmodulesrule=$(printf "|%s\.so" "${defaultenabledmodules[@]}")
defaultenabledmodulesrule=${defaultenabledmodulesrule:1}

apacheroot="/usr/local/apache2"
apacheconfroot="${apacheroot}/conf"

originalconf="${apacheconfroot}/original"

httpdconf="httpd.conf"
apacheconf="${apacheconfroot}/${httpdconf}"
apacheoriginalconf="${originalconf}/${httpdconf}"

awkremovecomment='{ \
if ($0 ~ /^[ \t]*#LoadModule/) {\
    if ($0 ~/'$defaultenabledmodulesrule'$/) {\
        #ucomment allowd modules
        sub(/^#/,"");print\
    } else {\
        # keep the LoadModule comments\
        print\
    }\
} else if ($0 ~ /^[ \t]*LoadModule/) {\
    if ($0 !~/'$defaultenabledmodulesrule'$/) {\
        # comment modules not inside the default allowed\
        print "#"$0\
    } else { \
        # keep the module unmodified\
        print\
    }\
} else if ($0 ~ /^[ \t]*#/) {\
# remove other comments\
} else {\
print\
}\
}'
awkremoveemptyline='/./'
cat $apacheoriginalconf | awk "$awkremovecomment" | awk $awkremoveemptyline > $apacheconf
}

if promptyn "process apr?";then
    cd $APR_SRC_DIR
    if promptyn "configure apr?";then
        echo "configure apr with configuration $APR_CONFIGURATION"
        $CONFIGURE -q $APR_CONFIGURATION
    fi
    if promptyn "make apr?";then
        make -C $APR_SRC_DIR
    fi
    if promptyn "install apr?";then
        make -C $APR_SRC_DIR install
    fi
fi

if promptyn "process apr-iconv?";then
    cd $APR_ICONV_DIR
    if promptyn "configure apr-iconv?";then
        echo "configure apr with configuration $APR_ICONV_CONFIGURATION"
        $CONFIGURE -q $APR_ICONV_CONFIGURATION
    fi
    if promptyn "make apr-iconv?";then
        make -C $APR_ICONV_DIR
    fi
    if promptyn "install apr-iconv?";then
        make -C $APR_ICONV_DIR install
    fi
fi

if promptyn "process PCRE?";then
    cd $PCRE_SRC_DIR
    if promptyn "configure PCRE?";then
        echo "configure PCRE with configuration $PCRE_CONFIGURATION"
        $CONFIGURE -q $PCRE_CONFIGURATION
    fi
    if promptyn "make PCRE?";then
        make -C $PCRE_SRC_DIR
    fi
    if promptyn "install PCRE?";then
        make -C $PCRE_SRC_DIR install
    fi
fi

if promptyn "process apr-util?";then
    dependspackages "libldap2-dev" "libssl-dev" "openssl"
    cd $APR_UTIL_SRC_DIR
    if promptyn "configure apr-util?";then
        echo "configure apr with configuration $APR_UTIL_CONFIGURATION"
        $CONFIGURE $APR_UTIL_CONFIGURATION
    fi
    if promptyn "make apr-util?";then
        make -C $APR_UTIL_SRC_DIR
    fi
    if promptyn "install apr-util?";then
        dependspackages "libexpat1-dev"
        make -C $APR_UTIL_SRC_DIR install
    fi
fi

if promptyn "process httpd?";then
    dependspackages "zlib1g-dev" "liblua5.1-0-dev"
    cd $HTTPD_SRC_DIR
    if promptyn "configure httpd?";then
        echo "configure httpd with configuration $HTTPD_CONFIGURATION"
        $CONFIGURE $HTTPD_CONFIGURATION
    fi
    if promptyn "make httpd?";then
        make -C $HTTPD_SRC_DIR
    fi
    if promptyn "install httpd?";then
        make -C $HTTPD_SRC_DIR install
    fi
    if promptyn "config apache and tools?";then
        configApache
        installTools
    fi
fi
