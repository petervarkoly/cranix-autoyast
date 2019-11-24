#!/bin/bash
. /etc/sysconfig/clock
. /etc/sysconfig/keyboard
. /etc/sysconfig/schoolserver
if [ ! -e /root/.ssh/id_rsa.pub ]; then
	/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
	cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
fi
keyroot=`cat /root/.ssh/id_rsa.pub`
LANGUAGE=${LANG:0:5}
crypt_root_password=`cat /etc/shadow | gawk -F : ' /^root/ { print $2 }'`
current_kbd=`echo $YAST_KEYBOARD | gawk -F , '{ print $1 }'`
READERDN=$( oss_get_dn.sh ossreader | sed 's/dn: //' )
BASEDN=$( ldbsearch -H /var/lib/samba/private/sam.ldb objectClass=domain dn | grep dn: | sed 's/dn: //' )
DATE=`/usr/share/oss/tools/oss_date.sh`


for i in  /srv/ftp/akt/xml/*xml.templ /srv/ftp/akt/xml/classes/*/*xml.templ /srv/ftp/akt/xml/files/*.templ
do
  name=`echo -n $i | sed 's/.templ//'`
  if [ -e "$name" ]
  then
    cp "$name" "$name.$DATE"
  fi
  cp $i $name
  sed -i "s#ADMINPASSWD#$crypt_root_password#g"  $name
  sed -i "s#READERDN#$READERDN#g"  $name
  sed -i "s#BASEDN#$BASEDN#g"  $name
  sed -i "s#DOMAIN#$SCHOOL_DOMAIN#g"  $name
  sed -i "s#SERVER_NET#$SCHOOL_SERVER_NET#g"  $name
  sed -i "s#BACKUP_SERVER#$SCHOOL_BACKUP_SERVER#g"  $name
  sed -i "s#NETMASK#$SCHOOL_NETMASK#g"  $name
  sed -i "s#@SERVER@#$SCHOOL_SERVER#g"  $name
  sed -i "s#GATEWAY#$SCHOOL_NET_GATEWAY#g"  $name
  sed -i "s#KEYROOT#$keyroot#g"  $name
  sed -i "s#TIMEZONE#$TIMEZONE#g"  $name
  sed -i "s#LANGUAGE#$LANGUAGE#g"  $name
  sed -i "s#CURRENT_KBD#$current_kbd#g"  $name
done

for i in /srv/tftp/pxelinux.cfg/autoyast*in
do
    cp $i /srv/tftp/pxelinux.cfg/$( basename $i .in )
done
