ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = CCSettings
CCSettings_FILES = Tweak.xm
CCSettings_FRAMEWORKS = UIKit CoreTelephony CoreLocation Preferences
CCSettings_PRIVATE_FRAMEWORKS = GraphicsServices

BUNDLE_NAME = CCSettingsPreferences
CCSettingsPreferences_FILES = CCSettingsPreferences.mm
CCSettingsPreferences_INSTALL_PATH = /Library/PreferenceBundles
CCSettingsPreferences_FRAMEWORKS = UIKit
CCSettingsPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
