#!/bin/bash
. /etc/sysconfig/clock
. /etc/sysconfig/keyboard
. /etc/sysconfig/cranix
if [ ! -e /root/.ssh/id_rsa.pub ]; then
	/usr/bin/ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
	cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
fi
keyroot=`cat /root/.ssh/id_rsa.pub`
LANGUAGE=${LANG:0:5}
crypt_root_password=`cat /etc/shadow | gawk -F : ' /^root/ { print $2 }'`
current_kbd=`echo $YAST_KEYBOARD | gawk -F , '{ print $1 }'`
READERDN=$( crx_get_dn.sh ossreader | sed 's/dn: //' )
BASEDN=$( ldbsearch -H /var/lib/samba/private/sam.ldb objectClass=domain dn | grep dn: | sed 's/dn: //' )
DATE=`/usr/share/cranix/tools/crx_date.sh`


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
  sed -i "s#DOMAIN#$CRANIX_DOMAIN#g"  $name
  sed -i "s#REALM#${CRANIX_DOMAIN^^}#g"  $name
  sed -i "s#CRANIX_WORKGROUP#$CRANIX_WORKGROUP#g"  $name
  sed -i "s#SERVER_NET#$CRANIX_SERVER_NET#g"  $name
  sed -i "s#BACKUP_SERVER#$CRANIX_BACKUP_SERVER#g"  $name
  sed -i "s#NETMASK#$CRANIX_NETMASK#g"  $name
  sed -i "s#@SERVER@#$CRANIX_SERVER#g"  $name
  sed -i "s#GATEWAY#$CRANIX_NET_GATEWAY#g"  $name
  sed -i "s#KEYROOT#$keyroot#g"  $name
  sed -i "s#TIMEZONE#$TIMEZONE#g"  $name
  sed -i "s#LANGUAGE#$LANGUAGE#g"  $name
  sed -i "s#CURRENT_KBD#$current_kbd#g"  $name
done

if [ ! -e /srv/tftp/pxelinux.cfg/autoyast ]; 
then
       	cp /srv/tftp/pxelinux.cfg/autoyast.in /srv/tftp/pxelinux.cfg/autoyast
fi
mkdir -p /home/software/linux/profiles/
install -m 755 /usr/share/cranix/templates/autoyast/* /home/software/linux/profiles/

if [ -z "$( grep 'Backup Server' /srv/tftp/efi/grub.cfg )" ]; then
echo "
menuentry 'Backup Server' {
  set timeout=120
  echo 'Loading kernel ...'
  linuxefi linux install=ftp://install/akt/CD1 autoyast=ftp://install/akt/xml/backup.xml insecure=1
  echo 'Loading initial ramdsik ...'
  initrdefi initrd
}
" >> /srv/tftp/efi/grub.cfg
fi

if [ -z "$( grep 'Backup Server' /srv/tftp/pxelinux.cfg/default )" ]; then
echo "
LABEL Backup Server installieren
        KERNEL linux
        APPEND initrd=initrd autoyast=ftp://install/akt/xml/backup.xml install=ftp://install/akt/CD1/ insecure=1
" >> /srv/tftp/pxelinux.cfg/default
fi
