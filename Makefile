VERSION = 1.0.0
PACKAGE = battery-mqtt-monitor
DEB = releases/$(PACKAGE)_$(VERSION)_all.deb

.PHONY: build clean

build:
	mkdir -p releases
	chmod 755 package/DEBIAN/postinst
	chmod 755 package/DEBIAN/prerm
	chmod 755 package/usr/bin/battery-mqtt-monitor
	chmod 600 package/etc/battery-mqtt-monitor/config
	dpkg-deb --build package $(DEB)
	@echo ""
	@echo "✔ Package built: $(DEB)"
	@echo "  Install with: sudo dpkg -i $(DEB)"

clean:
	rm -f releases/*.deb
