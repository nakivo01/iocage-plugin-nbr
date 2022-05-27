#!/bin/sh

PRODUCT='NAKIVO Backup & Replication'
URL="https://doc-14-ak-docs.googleusercontent.com/docs/securesc/1fhbp45jna4qhtbntdb7no6a57u617uq/k9o7e81ooaf5c0ork8f03s14gi6i6bun/1653632700000/18321531901525745641/02931601242818078698/1EKa-t-Gedtc2rbcfMHPFF1RdC1QmjmH0?e=download&ax=ACxEAsaj0djFvDMUOpUBxudTwMI5yrmuxHBc1nMBawouFjX4ReNXxwQXffEyMD_26eRqLnQ2C3TwjaRIC_d5ixtuonUxpd2karbOfrxAp3CGyj7uEGedxEw5BR1d54QPLZMlLbbU70KUfTQx2Gfqg1aJ6ECz8sjoWofoiqQdJ9A1PIBmWPxfvcIloJD_8kT-lA41nB8q6_GypscVo8ZYsQoM5mKCysbBe1g8Rjx8_pFpp8V_pACJ8jZlL6VrqX_3t66nXabGW2VjJCOksJ2B5QM4HN2dwifD3wYpCHde1vhpnE0elknZbkY-TP6prdR-HEyPID720kGhPvFgTYtdPJH6pZm9B3-6pT8cxOr5aqeeR5WSfnXBTqxSLdDCUsbgTxVDOkISy_5kbep2tawjHMxRw18bVzy74u1rVLED-GgN_GI_KPFikpl7F_Brv5-YTXf54OgYNR23eyqXqBLLPC5ZLp9fX-9-4Hiz2gRXOrjAPnXbehnD71BL4Eu4V7O4OShazFd6IURwPmIaKmpQqAVbgNhudmkx3Zw6BiUvGM67QiwPHe8mqk4WaoEm56TQRCkvOqhwvClUM0HWfuxrEcwgqnuqNGR2lhvgXIZz8MJHnuSfuT4S9Z01TWDFkODQzEiHjuw_gZY1qDMJGUoPFYA3DYPwu6kMPbXlkTdJrAxG7LZzZXJhyY-TH6vq9xeHfyibswts2zTidiL0HiM7wc35RX1hsvcTi93cKKE99dKJWyYujBAB2XisxkLEwkkk3W7XN20TZ4AKVrjWZcocgWx0mZZhdtLnI5VI-mM6WpPvDCFHpdx7VvU9sw&authuser=0"
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
