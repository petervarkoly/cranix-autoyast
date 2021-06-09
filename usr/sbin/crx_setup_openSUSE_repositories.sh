#!/bin/bash

USAGE="\n
crx_setup_openSUSE_repositories.sh  [-v Version] [-ueh ]\n
\n
\t\t-V Version\tThe openSUSE version: 15.3.\n
\t\t-u\t\tSynchronize update repository.\n
\t\t-e\t\tSynchronize education repository.\n
\t\t-t\t\tSynchronize terminalserver repository.\n
\t\t-p\t\tSynchronize PACKMAN repository.\n
\t\t-h\t\tThis page\n
"

VERSION="15.3"
UPDATE="no"
EDUCATION="no"
TERMINALSERVER="no"
PACKMAN="no"
SERVER="rsync.opensuse.org"

while getopts "V:uetvph" c
do
        case $c in
        V)      VERSION="$OPTARG"
		 ;;
	u)	UPDATE="yes"
		;;
	e)	EDUCATION="yes"
		;;
	t)	TERMINALSERVER="yes"
		;;
	p)	PACKMAN="yes"
		;;
        h)      echo -e $USAGE 1>&2
                exit 2
                ;;
        esac
done

mkdir -p /srv/ftp/akt/{CD1,xml,non-oss,OSS,updates,updates-non-oss}
if [ -e /srv/ftp/akt/RC1/ ]; then
   rm -rf /srv/ftp/akt/RC1/
fi

. /etc/sysconfig/cranix
RSYNC_PASSWORD=${SCHOOL_REG_CODE:10:9}
RSYNC_USER=${SCHOOL_REG_CODE:0:9}
export RSYNC_PASSWORD
RSYNC_PARAMS="-avz --stats --delete --delete-after --exclude=src --exclude=ppc --exclude=aarch64 --exclude=aarch64_ilp32 --exclude=armv7hl"

rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-full/opensuse/distribution/leap/${VERSION}/repo/oss/     /srv/ftp/akt/CD1/
rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-full/opensuse/distribution/leap/${VERSION}/repo/non-oss/ /srv/ftp/akt/non-oss/

if [ $UPDATE = "yes" ]; then
	rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/oss/     /srv/ftp/akt/updates/
	rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/non-oss/ /srv/ftp/akt/updates-non-oss/
    echo "#!/bin/bash
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/oss/     /srv/ftp/akt/updates/
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/non-oss/ /srv/ftp/akt/updates-non-oss/
" > /etc/cron.weekly/crx.openSUSE-updates
fi

#Download Education Packages
if [ "$EDUCATION" = "yes" ]; then
	rsync ${RSYNC_PARAMS} ${SERVER}::buildservice-repos-main/Education/openSUSE_Leap_${VERSION}/     /srv/ftp/akt/Education/
    echo "#!/bin/bash
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::buildservice-repos-main/Education/openSUSE_Leap_${VERSION}/     /srv/ftp/akt/Education/
" > /etc/cron.weekly/crx.Education-update
fi

#Dowload PACMAN
if [ "$PACKMAN" = "yes" ]; then
    rsync -avz --stats --delete --delete-after --exclude=src --exclude=ppc $RSYNC_USER@repo.cephalix.eu::PACKMAN/$VERSION/ /srv/ftp/akt/packman/
    echo "#!/bin/bash
. /etc/sysconfig/cranix
RSYNC_PASSWORD=\${SCHOOL_REG_CODE:10:9}
RSYNC_USER=\${SCHOOL_REG_CODE:0:9}
export RSYNC_PASSWORD
rsync -avz --stats --delete --delete-after --exclude=src --exclude=ppc \$RSYNC_USER@repo.cephalix.eu::PACKMAN/$VERSION/  /srv/ftp/akt/packman/
" > /etc/cron.weekly/crx.PACKMAN-update
fi

#Make updte cron jobs executable:
chmod 755 /etc/cron.weekly/crx.*

#Create tftp-boot environment
cd /srv/ftp
#Remove old symlinks
rm initrd  initrd64  linux  linux64

#Create the new symlinks for kernel and initrd
ln -s akt/CD1/boot/x86_64/loader/initrd initrd
ln -s akt/CD1/boot/x86_64/loader/linux  linux

cp * /srv/tftp

