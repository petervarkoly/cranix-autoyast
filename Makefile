#
# Copyright (c) Peter Varkoly Nürnberg, Germany.  All rights reserved.
#
DESTDIR         = /
TOPACKAGE       = Makefile etc  templates  LICENSE  README.md  srv  usr
HERE            = $(shell pwd)
REPO            = /data1/OSC/home:pvarkoly:CRANIX
PACKAGE         = cranix-autoyast2

install:
	mkdir -p $(DESTDIR)/usr/share/cranix/templates/autoyast/
	mkdir -p $(DESTDIR)/srv/ftp/akt/CD1
	rsync -av etc/       $(DESTDIR)/etc/
	rsync -av templates/ $(DESTDIR)/usr/share/cranix/templates/autoyast/
	rsync -av srv/       $(DESTDIR)/srv/
	rsync -av usr/       $(DESTDIR)/usr/

dist:
	xterm -e git log --raw  &
	if [ -e $(PACKAGE) ] ;  then rm -rf $(PACKAGE) ; fi
	mkdir $(PACKAGE)
	for i in $(TOPACKAGE); do \
	    cp -rp $$i $(PACKAGE); \
	done
	find $(PACKAGE) -type f > files;
	tar jcpf $(PACKAGE).tar.bz2 -T files;
	rm files
	rm -rf $(PACKAGE)
	if [ -d $(REPO)/$(PACKAGE) ] ; then \
	   cd $(REPO)/$(PACKAGE); osc up; cd $(HERE);\
	   mv $(PACKAGE).tar.bz2 $(REPO)/$(PACKAGE); \
	   cd $(REPO)/$(PACKAGE); \
	   osc vc; \
	   osc ci -m "New Build Version"; \
	fi

configure:
	/usr/sbin/crx_config_xml_files.sh
