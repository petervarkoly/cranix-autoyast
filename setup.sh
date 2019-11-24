DIR=`pwd`
if [ $UID != 0 ]; then
   echo ""
   echo "Only root can use this script."
   echo ""
   return 0
fi

VERSION=15.1
ARG="-V 15.1 -e"
zypper -n install wget
wget -O opensuse-${VERSION}.tgz http://repo.openschoolserver.net/downloads/autoyast/${VERSION}/opensuse-${VERSION}.tgz
if [ -e /srv/ftp/akt/CD1/content ]; then
    IS132=$( grep "opensuse:${VERSION}" /srv/ftp/akt/CD1/content )
    if [ -z "$IS132" ]; then
        OLDVERSION=$( /usr/share/oss/tools/oss_date.sh )
        echo "In /srv/ftp/akt/ there are old installation repositories. Do you to backup or to remove it (b/r)."
        read BACKUP
        if [ "$BACKUP" = "b" ]; then
                mv /srv/ftp/akt/ /srv/ftp/$OLDVERSION;
                echo "A backup of your repositories was created: /srv/ftp/$OLDVERSION"
        elif [ "$BACKUP" = "r" ]; then
                mkdir -p /srv/ftp/$OLDVERSION/xml
                rsync -a /srv/ftp/akt/xml/ /srv/ftp/$OLDVERSION/xml/
                rm -r /srv/ftp/akt/*
        else
                echo "'$BACKUP' is an illegal answer. Please start the script again"
                exit 1;
        fi
    fi
fi

tar xvf opensuse-${VERSION}.tgz -C /
/usr/sbin/oss_config_xml_files.sh

echo -n "Sync Update Repositories also (yes/no):"
read a
if [ "$a" = "yes" ]; then
   ARG="$ARG -u"
fi

echo -n "Sync Packman Repositories also (yes/no):"
read a
if [ "$a" = "yes" ]; then
   ARG="$ARG -p"
fi

/usr/sbin/oss_setup_pxe_enviroment.sh
echo ""
echo ""
echo "We start downloading the openSUSE ${VERSION} installation repositories."
echo "You need at last 50G in /srv/ftp."
echo "Download is only avaiable for customer with valid regcode."
echo "If the dowload brakes start it again by executing:"
echo "   oss_setup_openSUSE_repositories.sh $ARG"
echo -n "Do you want to start downloading? (yes/no) "
read a
if [ "$a" = "yes" ]; then
    nohup /usr/sbin/oss_setup_openSUSE_repositories.sh ${ARG} &
    echo ""
    echo "The download was started in backround. It can take a some hours."
    echo "The status you can obtain by executing tail -f $PWD/nohup.out."
fi

echo ""
echo ""
echo "Do not forget to activate the openSUE installation in /srv/tftp/pxelinux.cfg/default!"
echo ""
echo ""
cd $DIR
rm opensuse-${VERSION}.tgz setup.sh
