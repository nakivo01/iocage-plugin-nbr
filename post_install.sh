#!/bin/sh

PRODUCT='NAKIVO Backup & Replication'
URL="https://doc-14-ak-docs.googleusercontent.com/docs/securesc/1fhbp45jna4qhtbntdb7no6a57u617uq/1gokjjc0agco32vbctah597rh3jbl3pd/1653632325000/18321531901525745641/02931601242818078698/1EKa-t-Gedtc2rbcfMHPFF1RdC1QmjmH0?e=download&ax=ACxEAsbisbJm2tQ6B6m8JRIztO-e_k7_7mKD5MJcJRE6VmqY35KDnFjy_KajSQoYYbrCBL-Emvb9wsalvPoL4Ip_jZy4BqtgYKQNV03VY2rmCECPu061WK-99zGcmvYc_GIbtdzAWgggcbMbb6Pc1liVr3i3qFsQfO0q1C_CKBkarCjPmy0Tfg-XeK3gcy8reGA0KMXONRaVlbeqE5TePH36JPgIVpZkOaCzPlzREw0kZJs_9AN75tk3V78zk9i2Oe0Ik34zwd_ZNbAK1ZCXOZhRPR572wiKSARE0Ww-sjsrsZYWm4TMPb1Vf4o-0b4iCtIxALJhl3KGysCv2SPrx3HeuSf0uGUwXTlKRfAeCyjlz_ZP1tHNNfUue1YIwSX35ZVRYCj47uQw7dXFmM29JJZY5RI7oovwlCb5H-DdJQ1YhrTDzgYDm2TGBnZvNng4xtENV7yPe4yVZQx5XeVYZQ-xY8Ja7nq24blXKvOK7afj1v90p7cAGOZqDezdFzi24twiBDhSah59kWfa_wtZ1Ofi81YJWfGNC2RcZvFewvjhzz9WFecZHwn8KsSquuVhVP8Gew451w0xjSpNLBwYqZ-XiSfUZDk3MKcvmLhH78zRZ8IgJgd_qtL9aIBzgazuKGUYthOu2JvZSAxr5s-te_4AAfiDp_wFTlBhMfHEWq0WRMIjcpVdZmiCQNRnGjO2dguviiCRAmaWqX8&authuser=0&nonce=hein5b3qpkb3q&user=02931601242818078698&hash=9kq784e63119rv0hb0ngn1imn72385nq"
SHA256="03df344be4261f6e39044b1fd5515da78fb30fe64422d37bef46d0081c8ece39"

PRODUCT_ROOT="/usr/local/nakivo"
INSTALL="inst.sh"

curl --fail --tlsv1.2 -o $INSTALL $URL
if [ $? -ne 0 -o ! -e $INSTALL ]; then
    echo "ERROR: Failed to get $PRODUCT installer"
    rm $INSTALL >/dev/null 2>&1
    exit 1
fi

CHECKSUM=`sha256 -q $INSTALL`
if [ "$SHA256" != "$CHECKSUM" ]; then
    echo "ERROR: Incorrect $PRODUCT installer checksum"
    rm $INSTALL >/dev/null 2>&1
    exit 2
fi

sh ./$INSTALL -f -y -i "$PRODUCT_ROOT" --eula-accept --extract 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: $PRODUCT install failed"
    rm $INSTALL >/dev/null 2>&1
    exit 3
fi
rm $INSTALL >/dev/null 2>&1

#disable default HTTP ports redirect
SVC_PATH="$PRODUCT_ROOT/director"
awk 'BEGIN{A=0} /port="80/{A=1} {if (A==0) print $0} />/{A=0}' $SVC_PATH/tomcat/conf/server-linux.xml >$SVC_PATH/tomcat/conf/server-linux.xml_ 2>/dev/null
mv $SVC_PATH/tomcat/conf/server-linux.xml_ $SVC_PATH/tomcat/conf/server-linux.xml >/dev/null 2>&1

#enforce EULA
PROFILE=`ls "$SVC_PATH/userdata/"*.profile 2>/dev/null | head -1`
if [ "x$PROFILE" != "x" ]; then
    sed -e 's@"system.licensing.eula.must.agree": false@"system.licensing.eula.must.agree": true@' "$PROFILE" >"${PROFILE}_" 2>/dev/null
    mv "${PROFILE}_" "$PROFILE" >/dev/null 2>&1
fi

service nkv_dirsvc start >/dev/null 2>&1
