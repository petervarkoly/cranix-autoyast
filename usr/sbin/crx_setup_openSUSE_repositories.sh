#!/bin/bash

USAGE="\n
crx_setup_openSUSE_repositories.sh  [-v Version] [-ueh ]\n
\n
\t\t-V Version\tThe openSUSE version: 15.3.\n
\t\t-o\t\tDo not synchronize the repositories. Configure online installation.\n
\t\t-u\t\tSynchronize update repository.\n
\t\t-e\t\tSynchronize education repository.\n
\t\t-t\t\tSynchronize terminalserver repository.\n
\t\t-p\t\tSynchronize PACKMAN repository.\n
\t\t-h\t\tThis page\n
"

VERSION="15.6"
ONLINE="no"
UPDATE="no"
EDUCATION="no"
TERMINALSERVER="no"
PACKMAN="no"
SERVER="rsync.opensuse.org"
DATE=$( /usr/share/cranix/tools/crx_date.sh )

while getopts "V:uetvph" c
do
        case $c in
        V)      VERSION="$OPTARG"
		 ;;
	o)	ONLINE="yes"
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

if [ "${ONLINE}" == "yes" ]; then
cp /srv/ftp/akt/xml/classes/common/addons.xml  /srv/ftp/akt/xml/classes/common/addons.xml.$DATE
echo > /srv/ftp/akt/xml/classes/common/addons.xml <<EOF
<?xml version="1.0"?>
<!DOCTYPE profile>
<profile xmlns="http://www.suse.com/1.0/yast2ns" xmlns:config="http://www.suse.com/1.0/configns">
<add-on>
  <add_on_products config:type="list">
    <listentry>
      <media_url>http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_${VERSION}/</media_url>
      <product>PACKMAN</product>
      <product_dir>/</product_dir>
      <ask_on_error config:type="boolean">false</ask_on_error>
      <name>PACKMAN</name>
      <priority config:type="integer">10</priority>
    </listentry>
    <listentry>
      <media_url>http://download.opensuse.org/distribution/leap/${VERSION}/repo/oss/</media_url>
      <product>openSUSE-${VERSION}</product>
      <product_dir>/</product_dir>
      <ask_on_error config:type="boolean">false</ask_on_error>
      <name>openSUSE-${VERSION}</name>
      <priority config:type="integer">20</priority>
    </listentry>
    <listentry>
      <media_url>http://download.opensuse.org/update/leap/${VERSION}/oss/</media_url>
      <product>openSUSE-Updates</product>
      <product_dir>/</product_dir>
      <ask_on_error config:type="boolean">false</ask_on_error>
      <name>openSUSE-Updates</name>
      <priority config:type="integer">20</priority>
    </listentry>
    <listentry>
      <media_url>http://download.opensuse.org/update/leap/${VERSION}/sle/</media_url>
      <product>SLE15-Updates</product>
      <product_dir>/</product_dir>
      <ask_on_error config:type="boolean">false</ask_on_error>
      <name>SLE15-Updates</name>
      <priority config:type="integer">20</priority>
    </listentry>
    <listentry>
      <media_url>ftp://install/akt/education</media_url>
      <product>openSUSE-Education</product>
      <product_dir>/</product_dir>
      <ask_on_error config:type="boolean">false</ask_on_error>
      <name>openSUSE-Education</name>
      <priority config:type="integer">20</priority>
    </listentry>
  </add_on_products>
</add-on>
</profile>
EOF
fi

mkdir -p /srv/ftp/akt/{CD1,xml,non-oss,OSS,updates,updates-non-oss}
if [ -e /srv/ftp/akt/RC1/ ]; then
   rm -rf /srv/ftp/akt/RC1/
fi

. /etc/sysconfig/cranix
RSYNC_PARAMS="-avz --stats --delete --delete-after --exclude=src --exclude=ppc64le --exclude=aarch64 --exclude=aarch64_ilp32 --exclude=armv7hl --exclude=s390x"

rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-full/opensuse/distribution/leap/${VERSION}/repo/oss/     /srv/ftp/akt/CD1/
rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-full/opensuse/distribution/leap/${VERSION}/repo/non-oss/ /srv/ftp/akt/non-oss/

if [ $UPDATE = "yes" ]; then
	rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/oss/     /srv/ftp/akt/updates/
	rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/non-oss/ /srv/ftp/akt/updates-non-oss/
	rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/sle/     /srv/ftp/akt/updates-sle/
    echo "#!/bin/bash
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/oss/     /srv/ftp/akt/updates/
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/non-oss/ /srv/ftp/akt/updates-non-oss/
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::opensuse-updates/leap/${VERSION}/sle/     /srv/ftp/akt/updates-sle/
" > /etc/cron.weekly/crx.openSUSE-updates
fi

#Download Education Packages
if [ "$EDUCATION" = "yes" ]; then
	rsync ${RSYNC_PARAMS} ${SERVER}::buildservice-repos-main/Education/${VERSION}/     /srv/ftp/akt/education/
    echo "#!/bin/bash
/usr/bin/rsync ${RSYNC_PARAMS} ${SERVER}::buildservice-repos-main/Education/${VERSION}/     /srv/ftp/akt/education/
" > /etc/cron.weekly/crx.Education-update
fi

#Dowload PACMAN
if [ "$PACKMAN" = "yes" ]; then
    rsync ${RSYNC_PARAMS} rsync://ftp.halifax.rwth-aachen.de/packman/suse/openSUSE_Leap_$VERSION/ /srv/ftp/akt/packman/
    echo "#!/bin/bash
rsync ${RSYNC_PARAMS} rsync://ftp.halifax.rwth-aachen.de/packman/suse/openSUSE_Leap_$VERSION/ /srv/ftp/akt/packman/
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

