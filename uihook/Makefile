GO_EASY_ON_ME = 1
include theos/makefiles/common.mk

TWEAK_NAME = UIHook
UIHook_FILES = Tweak.xm
include $(THEOS_MAKE_PATH)/tweak.mk

dist:
	rm -rf Release
	mkdir Release
	mkdir Release/Library/
	mkdir Release/Library/MobileSubstrate
	mkdir Release/Library/MobileSubstrate/DynamicLibraries
	cp "$(TWEAK_NAME).plist" "Release/Library/MobileSubstrate/DynamicLibraries/" 
	cp "obj/$(TWEAK_NAME).dylib" "Release/Library/MobileSubstrate/DynamicLibraries/" 
	mkdir Release/DEBIAN
	cp "control" "Release/DEBIAN" 
	for i in $( find ./Release | grep -i ".DS" ); do rm -rf "$i"; done
	/opt/local/bin/dpkg-deb -b ./Release 
	mscp "$(TWEAK_NAME)"
#include $(THEOS_MAKE_PATH)/tweak.mk
