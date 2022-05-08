TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = YouTube


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YTUMG

YTUMG_FILES = Tweak.xm
YTUMG_CFLAGS = -fobjc-arc

YTUMG_PRIVATE_FRAMEWORKS = OnBoardingKit
include $(THEOS_MAKE_PATH)/tweak.mk
