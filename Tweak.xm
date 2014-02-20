/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

#import <objc/runtime.h>
#import <dlfcn.h>
#import <notify.h>
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>

struct CopyDataInfo
{
    int dummy1;
    int dummy2;
};

static void _callback(){
	//Do nothing;
};

static NSBundle *localBundle = nil;
static NSDictionary *orderSetting = nil;
static NSDictionary *orderQuickSetting = nil;
static int CCSTogglePerLine = 5;
static BOOL CCSDismissControlCenter = NO;
static int CCSNetworkMode = 0;
static BOOL CCSKillMusic = NO;
static BOOL CCSDismissControlCenterKB = NO;
static int CCSQLClockType = 3;
static NSDictionary *hideWhenLocked = nil;
static BOOL lastLockStatus = YES;
static NSDictionary *whiteList = nil;


@interface UIView (Private)
-(BOOL)_shouldAnimatePropertyWithKey:(id)key;
@end

@interface SBControlCenterButton
+(id)circularButtonWithGlyphImage:(UIImage*)image;
+(id)roundRectButtonWithGlyphImage:(id)arg1;
@property(copy, nonatomic) NSString* identifier;
@property(copy, nonatomic) NSNumber* sortKey;
@property(nonatomic,assign) id delegate;
@end

@interface SpringBoard
-(void)_lockButtonUpFromSource:(int)source;
-(void)powerDown;
-(void)reboot;
-(void)relaunchSpringBoard;
-(BOOL)isLocked;
-(id)_accessibilityFrontMostApplication;
-(void)showSpringBoardStatusBar;
-(void)applicationOpenURL:(id)url publicURLsOnly:(BOOL)only;
@end

@interface SBMediaController
+(id)sharedInstance;
-(id)nowPlayingApplication;
-(BOOL)isPlaying;
@end

@interface SBUIController
+(id)sharedInstance;
-(BOOL)clickedMenuButton;
-(BOOL)handleMenuDoubleTap;
-(BOOL)_activateAppSwitcherFromSide:(int)side;
-(void)dismissSwitcherAnimated:(BOOL)animated;
-(id)switcherController;
@end

@interface SBApplication
@property(copy) NSString* displayIdentifier;
-(id)badgeNumberOrString;
-(void)setBadge:(id)badge;
@end

@interface SBAppSliderController
@property(readonly, assign, nonatomic) id iconController;
-(id)_displayIDAtIndex:(unsigned)index;
-(void)_quitAppAtIndex:(unsigned)index;
@end

@interface SBControlCenterController
+(id)sharedInstance;
-(BOOL)handleMenuButtonTap;
@end

@interface VPNBundleController
- (id)initWithParentListController:(id)fp8;
- (id)vpnActiveForSpecifier:(id)fp8;
- (void)_setVPNActive:(BOOL)fp8;
@end

@interface VPNConnectionStore
-(id)currentConnection;
- (void)reloadVPN;
@end

@interface VPNConnection
-(BOOL)needsPassword;
@end

@interface SBAppSwitcherModel
-(void)remove:(id)remove;
@end

#ifndef CTTELEPHONYCENTER_H_
CFNotificationCenterRef (*CTTelephonyCenterGetDefault)();
void (*CTTelephonyCenterAddObserver)(id ct, id observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior);
void (*CTTelephonyCenterRemoveObserver)(id ct, id observer, CFStringRef name, const void *object);
#endif

#ifndef CTCELLULARDATAPLAN_H_
Boolean (*CTCellularDataPlanGetIsEnabled)();
void (*CTCellularDataPlanSetIsEnabled)(Boolean enabled);
#endif

CHDeclareClass(VPNBundleController);
static VPNBundleController *vpnController;
static void PrepareVpn()
{
	CHLoadLateClass(VPNBundleController);
	vpnController = [CHAlloc(VPNBundleController) initWithParentListController:nil];
}

#define PrepareVpn() do { if (!vpnController) PrepareVpn(); } while(0)

void (*GSSendAppPreferencesChanged)(CFStringRef service_name, CFStringRef app_id);

#define kCCSettingsDismissLockThreadDictionaryKey @"CCSettingsDismissLock"

static NSInteger CCSettingsDismissLockStatus() {
    return [[[[NSThread currentThread] threadDictionary] objectForKey:kCCSettingsDismissLockThreadDictionaryKey] intValue];
}

static void CCSettingsSetDismissLockStatus(NSInteger loading) {
    [[[NSThread currentThread] threadDictionary] setObject:[NSNumber numberWithInt:loading] forKey:kCCSettingsDismissLockThreadDictionaryKey];
}


@interface SBControlCenterSectionView : UIView{
	float _edgePadding;
}
@property(assign, nonatomic) float edgePadding; 
-(BOOL)_shouldAnimatePropertyWithKey:(id)key;
@end

@implementation SBControlCenterSectionView
-(BOOL)_shouldAnimatePropertyWithKey:(id)key{
	BOOL res = [super _shouldAnimatePropertyWithKey:key];
	if (!res)
	{
		if ([key isEqualToString:@"hidden"])
		{
			return YES;
		}
		else {
			return NO;
		}
	}
	return YES;
}
@end

@interface SBCCButtonLayoutScrollView : SBControlCenterSectionView {
	NSMutableArray* _buttons;
	float _interButtonPadding;
	UIEdgeInsets _contentEdgeInsets;
	UIScrollView *_layview;
}
@property(assign, nonatomic) UIEdgeInsets contentEdgeInsets;
@property(assign, nonatomic) float interButtonPadding;
-(id)initWithFrame:(CGRect)frame;
-(void)dealloc;
-(void)addButton:(id)button;
-(void)removeButton:(id)button;
-(void)removeAllButtons;
-(id)buttons;
-(void)layoutSubviews;
@end

@implementation SBCCButtonLayoutScrollView

-(id)initWithFrame:(CGRect)frame{
	self = [super initWithFrame:frame];
	if (self)
	{
		_buttons = [[NSMutableArray alloc] init];
		_layview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		_layview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_layview.pagingEnabled = YES;
    	_layview.showsHorizontalScrollIndicator = NO;
    	_layview.showsVerticalScrollIndicator = NO;
		[self addSubview:_layview];
	}
	return self;
}

-(void)dealloc{
	[_buttons release];
	[super dealloc];
}


-(void)addButton:(id)button{
	if (![_buttons containsObject:button])
	{
		[_buttons addObject:button];
		[_layview addSubview:(UIView*)button];
		[_buttons sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		    NSInteger buttonID1 = [((SBControlCenterButton*)obj1).sortKey intValue];
		    NSInteger buttonID2 = [((SBControlCenterButton*)obj2).sortKey intValue];
		    if (buttonID1 < buttonID2)
		        return NSOrderedAscending;
		    else
		        return NSOrderedDescending;
		}];
		[self setNeedsLayout];
	}
}

-(void)removeButton:(id)button{
	if ([_buttons containsObject:button])
	{
		[_buttons removeObject:button];
		[(UIView*)button removeFromSuperview];
		[self setNeedsLayout];
	}
}

-(void)removeAllButtons{
	for (id button in _buttons)
	{
		[(UIView*)button removeFromSuperview];
	}
	[_buttons removeAllObjects];
}

-(id)buttons{
	id copyButtons = [_buttons copy];
	return [copyButtons autorelease];
}

-(void)layoutSubviews{
	float fixWidth = 16.0f;
	if (CCSTogglePerLine == 6)
	{
		fixWidth = 6.0f;
	}
	if ([_buttons count] > 0)
	{
		if (self.frame.size.width > self.frame.size.height)
		{
			CGSize _buttonSize = ((UIView*)[_buttons objectAtIndex:0]).frame.size;
			float _buttonPending = (self.frame.size.width - fixWidth * 2 - _buttonSize.width * CCSTogglePerLine - _contentEdgeInsets.left - _contentEdgeInsets.right) / (CCSTogglePerLine - 1);
			float _buttonTop = round((self.frame.size.height) - _contentEdgeInsets.top - _contentEdgeInsets.bottom - _buttonSize.height) / 2.0f;

			for (int i = 0; i < [_buttons count]; ++i)
			{
				UIView *button = [_buttons objectAtIndex:i];
				int _page = i / CCSTogglePerLine;
				int _loc = i % CCSTogglePerLine;
				int _buttonOrigX = round((fixWidth + _contentEdgeInsets.left + _buttonSize.width * _loc +  _buttonPending * _loc + self.frame.size.width * _page) * 2) / 2.0f;
				button.frame = CGRectMake(_buttonOrigX, _buttonTop, button.frame.size.width, button.frame.size.height);
			}
			int _totalPage = [_buttons count] / CCSTogglePerLine + (([_buttons count] % CCSTogglePerLine > 0)?1:0);
			[_layview setContentSize:CGSizeMake(_layview.frame.size.width * _totalPage, _layview.frame.size.height)];
		}
		else {
			CGSize _buttonSize = ((UIView*)[_buttons objectAtIndex:0]).frame.size;
			float _buttonPending = (self.frame.size.height - fixWidth * 2 - _buttonSize.height * CCSTogglePerLine - _contentEdgeInsets.top - _contentEdgeInsets.bottom) / (CCSTogglePerLine -1);
			float _buttonLeft = round((self.frame.size.width) - _contentEdgeInsets.left - _contentEdgeInsets.right - _buttonSize.width) / 2.0f;

			for (int i = 0; i < [_buttons count]; ++i)
			{
				UIView *button = [_buttons objectAtIndex:i];
				int _page = i / CCSTogglePerLine;
				int _loc = i % CCSTogglePerLine;
				int _buttonOrigY = round((fixWidth + _contentEdgeInsets.top + _buttonSize.height * _loc +  _buttonPending * _loc + self.frame.size.height * _page) * 2) / 2.0f;
				button.frame = CGRectMake(_buttonLeft, _buttonOrigY, button.frame.size.width, button.frame.size.height);
			}
			int _totalPage = ([_buttons count] - 1) / CCSTogglePerLine + ((([_buttons count] - 1) % CCSTogglePerLine > 0)?1:0);
			[_layview setContentSize:CGSizeMake(_layview.frame.size.width , _layview.frame.size.height * _totalPage)];
		}
	}

	[super layoutSubviews];
}

@end

@interface SBCCButtonLayoutScrollViewForQuickSection : SBCCButtonLayoutScrollView
@end

@implementation SBCCButtonLayoutScrollViewForQuickSection

-(void)layoutSubviews{
	float fixWidth = 16.0f;
	if ([_buttons count] > 0)
	{
		if (self.frame.size.width > self.frame.size.height)
		{
			CGSize _buttonSize = ((UIView*)[_buttons objectAtIndex:0]).frame.size;
			float _buttonPending = (self.frame.size.width - fixWidth * 2 - _buttonSize.width * 4 - _contentEdgeInsets.left - _contentEdgeInsets.right) / (4 - 1);
			float _buttonTop = round((self.frame.size.height) - _contentEdgeInsets.top - _contentEdgeInsets.bottom - _buttonSize.height) / 2.0f;

			for (int i = 0; i < [_buttons count]; ++i)
			{
				UIView *button = [_buttons objectAtIndex:i];
				int _page = i / 4;
				int _loc = i % 4;
				int _buttonOrigX = round((fixWidth + _contentEdgeInsets.left + _buttonSize.width * _loc +  _buttonPending * _loc + self.frame.size.width * _page) * 2) / 2.0f;
				button.frame = CGRectMake(_buttonOrigX, _buttonTop, button.frame.size.width, button.frame.size.height);
			}
			int _totalPage = [_buttons count] / 4 + (([_buttons count] % 4 > 0)?1:0);
			[_layview setContentSize:CGSizeMake(_layview.frame.size.width * _totalPage, _layview.frame.size.height)];
		}
		else {
			CGSize _buttonSize = ((UIView*)[_buttons objectAtIndex:0]).frame.size;
			float _buttonPending = (self.frame.size.height - fixWidth * 2 - _buttonSize.height * 4 - _contentEdgeInsets.top - _contentEdgeInsets.bottom) / (4 -1);
			float _buttonLeft = round((self.frame.size.width) - _contentEdgeInsets.left - _contentEdgeInsets.right - _buttonSize.width) / 2.0f;

			for (int i = 0; i < [_buttons count]; ++i)
			{
				UIView *button = [_buttons objectAtIndex:i];
				int _page = i / 4;
				int _loc = i % 4;
				int _buttonOrigY = round((fixWidth + _contentEdgeInsets.top + _buttonSize.height * _loc +  _buttonPending * _loc + self.frame.size.height * _page) * 2) / 2.0f;
				button.frame = CGRectMake(_buttonLeft, _buttonOrigY, button.frame.size.width, button.frame.size.height);
			}
			int _totalPage = ([_buttons count] - 1) / 4 + ((([_buttons count] - 1) % 4 > 0)?1:0);
			[_layview setContentSize:CGSizeMake(_layview.frame.size.width , _layview.frame.size.height * _totalPage)];
		}
	}
}

@end



@interface SBCCSettingsSectionController 
@property(assign, nonatomic) id delegate;
-(id)view;
-(id)_buttonForSetting:(int)setting;
-(id)_identifierForSetting:(int)setting;
-(void)_addButtonForSetting:(int)setting;
-(BOOL)_getMuted;

//CCSettingsAdded
-(void)_loadSettings;
-(NSNumber *)_orderForSetting:(int)setting;
-(void)_reloadButtons;

-(void)_initData;
-(void)_tearDownData;
-(BOOL)_getData;
-(void)_setDataEnabled:(BOOL)enabled;
-(void)_updateDataButtonState;

-(void)_initLocation;
-(void)_tearDownLocation;
-(BOOL)_getLocation;
-(void)_setLocationEnabled:(BOOL)enabled;
-(void)_updateLocationButtonState;

-(void)_initHotspot;
-(void)_tearDownHotspot;
-(BOOL)_getHotspot;
-(void)_reloadHotspot;
-(void)_setHotspotEnabled:(BOOL)enabled;
-(void)_updateHotspotButtonState;

-(void)_setLock;
-(void)_setShutdown;
-(void)_setReboot;
-(void)_setRespring;

-(NSDictionary *)_getRATState:(NSDictionary *)stateDictionary;
-(NSString *)_RATModeString;
-(BOOL)_RATSwitchAvailable;
-(BOOL)_get3G;
-(void)_set3GEnabled:(BOOL)enabled;
-(void)_init3G;
-(void)_tearDown3G;
-(void)_update3GButtonState;

-(void)_setHome;

-(void)_initVPN;
-(BOOL)_getVPN;
-(void)_setVPNEnabled:(BOOL)enabled;
-(void)_updateVPNButtonState;

-(void)_initVibrate;
-(void)_tearDownVibrate;
-(BOOL)_getVibrate;
-(void)_setVibrateEnabled:(BOOL)enabled;
-(void)_updateVibrateButtonState;

-(void)_delayScreenShot;
-(void)_setScreenShot;

-(int)_getAutoLock;
-(void)_setAutoLockEnabled:(BOOL)enabled;
-(void)_updateAutoLockButtonState;

-(void)_delayUpdateKillBackgroundButtonState;
-(void)_setKillBackground;
-(void)_setClearBadge;

-(void)_captureButtonForSetting:(int)setting;

-(BOOL)_fluxAvailable;
-(void)_initFlux;
-(void)_tearDownFlux;
-(BOOL)_getFlux;
-(void)_setFlux:(BOOL)enabled;
-(void)_updateFluxButtonState;

-(BOOL)_sshAvailable;
-(BOOL)_getSSH;
-(void)_setSSH:(BOOL)enabled;
-(void)_backgroundUpdateSSHButtonStatus;
-(void)_setSSHButtonStatus:(NSNumber *)enabled;
-(void)_updateSSHButtonStatus;

-(BOOL)_wpAvaiable;
-(BOOL)_getWP;
-(void)_setWP:(BOOL)enabled;
-(void)_updateWPButtonStatus;

@end

@interface SBCCQuickLaunchSectionController

-(id)view;
-(void)_activateAppWithBundleId:(id)bundleId url:(id)url;
-(id)_bundleIDForButton:(id)button;

-(NSNumber *)_orderForIdentifier:(NSString *)identifier;
-(void)_setHome;
-(void)_setLock;
-(void)_setScreenShot;
-(void)_reloadButtons;

@end

@interface SBCCButtonLayoutView 
-(void)addButton:(id)button;
@end

@interface SBControlCenterViewController
-(void)section:(id)section updateStatusText:(id)text reason:(id)reason;
-(void)section:(id)section publishStatusUpdate:(id)update;
@end

@interface SBControlCenterStatusUpdate
+(id)statusUpdateWithString:(id)string reason:(id)reason;
@end

@interface CLLocationManager
@property(readonly, assign, nonatomic) BOOL locationServicesEnabled;
+(void)setLocationServicesEnabled:(BOOL)enabled;
@end

typedef enum PSCellType {
	PSGroupCell,
	PSLinkCell,
	PSLinkListCell,
	PSListItemCell,
	PSTitleValueCell,
	PSSliderCell,
	PSSwitchCell,
	PSStaticTextCell,
	PSEditTextCell,
	PSSegmentCell,
	PSGiantIconCell,
	PSGiantCell,
	PSSecureEditTextCell,
	PSButtonCell,
	PSEditTextViewCell,
} PSCellType;

@interface PSRootController
-(id)initWithTitle:(id)title identifier:(id)identifier;
@end

@interface PSListController
-(id)initForContentSize:(CGSize)size;
-(void)setRootController:(id)controller;
-(void)setParentController:(id)controller;
@end

@interface PSSpecifier
+(id)preferenceSpecifierNamed:(NSString*)title target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(PSCellType)cell edit:(Class)edit;
@end

@interface WirelessModemController : PSListController {
}
- (id)internetTethering:(PSSpecifier *)specifier;
- (void)setInternetTethering:(id)value specifier:(PSSpecifier *)specifier;
@end

@interface SBScreenShotter
-(void)saveScreenshot:(BOOL)screenShot;
+(id)sharedInstance;
@end

@interface MCProfileConnection
+ (id)sharedConnection;
- (void)removeValueSetting:(id)arg1;
- (void)setValue:(id)arg1 forSetting:(id)arg2;
- (id)effectiveValueForSetting:(id)arg1;
@end

@interface SBIconController
+(id)sharedInstance;
@end

@interface SBIconModel
-(id)leafIcons;
@end

@interface SBAssistantController
+(id)sharedInstance;
-(void)dismissAssistantViewIfNecessary:(int)necessary;
-(void)_activateSiriForPPT;
@end

static void dataCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    [(SBCCSettingsSectionController*)observer _updateDataButtonState];
}

static void locationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
    [(SBCCSettingsSectionController*)observer _updateLocationButtonState];
}



static void registrationDataStatusChanged(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	NSString *oldModeSeting = [(SBCCSettingsSectionController*)observer _RATModeString];
    [(SBCCSettingsSectionController*)observer _getRATState:(NSDictionary*)userInfo];
    NSString *modeString = [(SBCCSettingsSectionController*)observer _RATModeString];
    if ([oldModeSeting compare:modeString])
    {
    	for (int i = 13; i < 16; ++i)
	    {
	    	if ([modeString compare:[(SBCCSettingsSectionController*)observer _identifierForSetting:i]])
	    	{
	    		id button = [(SBCCSettingsSectionController*)observer _buttonForSetting:i];
	    		[[(SBCCSettingsSectionController*)observer view] removeButton:button];
	    	}
	    	else {
	    		id button = [(SBCCSettingsSectionController*)observer _buttonForSetting:i];
	    		if (button != nil)
	    		{
	    			[[(SBCCSettingsSectionController*)observer view] addButton:button];
	    		}
	    		else {
	    			[(SBCCSettingsSectionController*)observer _addButtonForSetting:i];
	    		}
	    		
	    	}
	    }
    }
    [(SBCCSettingsSectionController*)observer _update3GButtonState];
}

static void vibrateCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)   
{
	BOOL mute = [(SBCCSettingsSectionController*)observer _getMuted];
    if ([(NSString*)name isEqualToString:@"com.apple.springboard.silent-vibrate.changed"])
    {
    	if (mute)
    	{
    		[(SBCCSettingsSectionController*)observer _updateVibrateButtonState];
    	}
    }
    else {
    	if (!mute)
    	{
    		[(SBCCSettingsSectionController*)observer _updateVibrateButtonState];
    	}
    }
}

static void fluxCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(SBCCSettingsSectionController*)observer _updateFluxButtonState];
}

static void ccsettingsOrderChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@synchronized(orderSetting) {
		[orderSetting release];
		orderSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.plist"];
		if (orderSetting == nil)
		{
			orderSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/Application Support/CCSettings/CCSettingsOrder.plist"];
		}
	}
	[(SBCCSettingsSectionController*)observer _reloadButtons];
}

/*
static void ccsettingsQuickOrderChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@synchronized(orderQuickSetting) {
		[orderQuickSetting release];
		orderQuickSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.quick.plist"];
		if (orderQuickSetting == nil)
		{
			orderQuickSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/Application Support/CCSettings/CCSettingsOrderQuick.plist"];
		}
	}
	[(SBCCQuickLaunchSectionController*)observer _reloadButtons];
}
*/

static void ccsettingsPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.preferences.plist"];
	if (settings != nil)
	{
		if ([settings objectForKey:@"TOGGLES_PER_LINE"] != nil)
		{
			int togglesPerLine = [[settings objectForKey:@"TOGGLES_PER_LINE"] intValue];
			if (togglesPerLine != CCSTogglePerLine)
			{
				CCSTogglePerLine = togglesPerLine;
				[(SBCCSettingsSectionController*)observer _reloadButtons];
			}
		}
		if ([settings objectForKey:@"DISMISS_CONTROL_CENTER"])
		{
			CCSDismissControlCenter = [[settings objectForKey:@"DISMISS_CONTROL_CENTER"] boolValue];
		}
		if ([settings objectForKey:@"NETWORK_MODE"])
		{
			int networkMode = [[settings objectForKey:@"NETWORK_MODE"] intValue];
			if (networkMode != CCSNetworkMode)
			{
				CCSNetworkMode = networkMode;
				NSString *modeString = [(SBCCSettingsSectionController*)observer _RATModeString];
		    	for (int i = 13; i < 16; ++i)
			    {
			    	if ([modeString compare:[(SBCCSettingsSectionController*)observer _identifierForSetting:i]])
			    	{
			    		id button = [(SBCCSettingsSectionController*)observer _buttonForSetting:i];
			    		[[(SBCCSettingsSectionController*)observer view] removeButton:button];
			    	}
			    	else {
			    		id button = [(SBCCSettingsSectionController*)observer _buttonForSetting:i];
			    		if (button != nil)
			    		{
			    			[[(SBCCSettingsSectionController*)observer view] addButton:button];
			    		}
			    		else {
			    			[(SBCCSettingsSectionController*)observer _addButtonForSetting:i];
			    		}
			    		
			    	}
			    }
			}
			[(SBCCSettingsSectionController*)observer _update3GButtonState];
		}
		if ([settings objectForKey:@"KILL_MUSIC"])
		{
			CCSKillMusic = [[settings objectForKey:@"KILL_MUSIC"] boolValue];
		}
		if ([settings objectForKey:@"DISMISS_CONTROL_CENTER_KB"])
		{
			CCSDismissControlCenterKB = [[settings objectForKey:@"DISMISS_CONTROL_CENTER_KB"] boolValue];
		}
		if ([settings objectForKey:@"CLOCK_TYPE"])
		{
			CCSQLClockType = [[settings objectForKey:@"CLOCK_TYPE"] intValue];
		}
	}
}

static void ccsettingsHideWhenLockedChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	@synchronized(hideWhenLocked) {
		[hideWhenLocked release];
		hideWhenLocked = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.hidewhenlocked.plist"];
		if (hideWhenLocked == nil)
		{
			hideWhenLocked = [[NSDictionary alloc] init];
		}
	}
	[(SBCCSettingsSectionController*)observer _reloadButtons];
}

static void ccsettingsWhiteListChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	@synchronized(whiteList) {
		[whiteList release];
		whiteList = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.whitelist.plist"];
		if (whiteList == nil)
		{
			whiteList = [[NSDictionary alloc] init];
		}
	}
}


%group WirelessModemController
%hook WirelessModemController
- (void)_btPowerChangedHandler:(NSNotification *)notification
{
}
%end
%end

%hook SBControlCenterController
-(void)_dismissWithDuration:(double)duration additionalAnimations:(id)animations completion:(id)completion{
	if (CCSettingsDismissLockStatus() != 1)
	{
		%orig;
	}
}
%end

%hook SBCCSettingsSectionController

+(id)viewClass{
	return objc_getClass("SBCCButtonLayoutScrollView");
}

-(id)init{
	id res = %orig;
	[self _initData];
	[self _initLocation];
	[self _initHotspot];
	[self _init3G];
	[self _initVPN];
	[self _initVibrate];
	if ([self _fluxAvailable])
	{
		[self _initFlux];
	}
	return res;
}

%new
-(NSNumber *)_orderForSetting:(int)setting{
	NSString *identifier = [self _identifierForSetting:setting];
	if (setting == 13 || setting == 14 || setting ==15)
	{
		identifier = @"3G4GLTE";
	}
	if (lastLockStatus == YES)
	{
		if ([[hideWhenLocked objectForKey:identifier] boolValue])
		{
			return [NSNumber numberWithInteger:-1];
		}
	}
	if ([orderSetting objectForKey:identifier])
	{
		return [NSNumber numberWithInteger:[[orderSetting objectForKey:identifier] intValue]];
	}
	else {
		return [NSNumber numberWithInteger:-1];
	}
}

%new
-(void)_reloadButtons{
	[[self view] removeAllButtons];
	int setting = 0;
	do {
		if ([[self _orderForSetting:setting] intValue] >= 0)
		{
			id button = [self _buttonForSetting:setting];
			if (button)
			{
				[button setSortKey:[self _orderForSetting:setting]];
				[[self view] addButton:button];
			}
			else {
				[self _addButtonForSetting:setting];
			}
		}
		setting++;
	}
	while (setting != 26);
	[self _updateLocationButtonState];
	[self _update3GButtonState];
	if ([self _fluxAvailable])
	{
		[self _updateFluxButtonState];
	}
}

-(void)_addButtonForSetting:(int)setting{
	if (setting < 6)
	{
		%orig;
		id button = [self _buttonForSetting:setting];
    	if (setting != 1 || !objc_getClass("WiPiListener")) {
    		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    		longPress.minimumPressDuration = 0.5f;
    		if (setting == 16)
    		{
    			longPress.minimumPressDuration = 2.0f;
    		}
    		[(UIView*)button addGestureRecognizer:longPress];
    		[longPress release];
    	}
		
		if ([[self _orderForSetting:setting] intValue] >= 0)
		{
			[button setSortKey:[self _orderForSetting:setting]];
		}
		else 
		{
			[[self view] removeButton:button];
		}
	}
	else {
		if ([[self _orderForSetting:setting] intValue] < 0)
		{
			return;
		}
		if (setting == 23)
		{
			if (![self _fluxAvailable])
			{
				return;
			}
		}
		if (setting == 24)
		{
			if (![self _sshAvailable])
			{
				return;
			}
		}
		if (setting == 25)
		{
			if (![self _wpAvaiable])
			{
				return;
			}
		}
		NSString *idenfitierForSetting = [self _identifierForSetting:setting];
		NSString *modeSeting = [self _RATModeString];
		if (setting == 13 || setting == 14 || setting ==15)
		{
			if ([modeSeting compare:idenfitierForSetting])
			{
				return;
			}
		}
		UIImage *buttonImage = nil;
		if (setting == 6)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphDataNetwork.png"];
		}
		if (setting == 7)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphLocationServices.png"];
		}
		if (setting == 8)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphPersonalHotspot.png"];
		}
		if (setting == 9)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphLock.png"];
		}
		if (setting == 10)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphShutdown.png"];
		}
		if (setting == 11)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphReboot.png"];
		}
		if (setting == 12)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphRespring.png"];
		}
		if (setting == 13)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyph3G.png"];
		}
		if (setting == 14)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyph4G.png"];
		}
		if (setting == 15)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphLTE.png"];
		}
		if (setting == 16)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphHome.png"];
		}
		if (setting == 17)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphVPN.png"];
		}
		if (setting == 18)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphVibrate.png"];
		}
		if (setting == 19)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphScreenShot.png"];
		}
		if (setting ==  20)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphAutoLock.png"];
		}
		if (setting ==  21)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphKillBackground.png"];
		}
		if (setting ==  22)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphClearBadge.png"];
		}
		if (setting == 23)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphFlux.png"];
		}
		if (setting == 24)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphSSH.png"];
		}
		if (setting == 25)
		{
			buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphWP.png"];
		}
		id button = [objc_getClass("SBControlCenterButton") circularButtonWithGlyphImage:buttonImage];
		[button setIdentifier:idenfitierForSetting];
		[button setSortKey:[self _orderForSetting:setting]];
		[button setDelegate:self];
		[(UIButton*)button setSelected:NO];
		[(UIButton*)button setTag:setting];
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    	longPress.minimumPressDuration = 1.0f;
    	[(UIView*)button addGestureRecognizer:longPress];
    	[longPress release];
		NSMutableDictionary* __buttonsByID =  (NSMutableDictionary*)[(id)self valueForKey:@"_buttonsByID"];
		[__buttonsByID setObject:button forKey:idenfitierForSetting];
		[[self view] addButton:button];
	}
}

-(id)_buttonForSetting:(int)setting{
	if (setting < 6)
	{
		return %orig;
	}
	else {
		NSMutableDictionary* __buttonsByID = (NSMutableDictionary*)[(id)self valueForKey:@"_buttonsByID"];
		return [__buttonsByID objectForKey:[self _identifierForSetting:setting]];
	}
}

-(id)_identifierForSetting:(int)setting{
	if (setting < 6)
	{
		return %orig;
	}
	else {
		if (setting == 6)
		{
			return @"data";
		}
		if (setting == 7)
		{
			return @"location";
		}
		if (setting == 8)
		{
			return @"hotspot";
		}
		if (setting ==9)
		{
			return @"lock";
		}
		if (setting ==10)
		{
			return @"shutdown";
		}
		if (setting ==11)
		{
			return @"reboot";
		}
		if (setting ==12)
		{
			return @"respring";
		}
		if (setting ==13)
		{
			return @"3G";
		}
		if (setting == 14)
		{
			return @"4G";
		}
		if (setting == 15)
		{
			return @"LTE";
		}
		if (setting == 16)
		{
			return @"home";
		}
		if (setting == 17)
		{
			return @"VPN";
		}
		if (setting == 18)
		{
			return @"vibrate";
		}
		if (setting == 19)
		{
			return @"screenShot";
		}
		if (setting == 20)
		{
			return @"autoLock";
		}
		if (setting == 21)
		{
			return @"killbackground";
		}
		if (setting == 22)
		{
			return @"clearBadge";
		}
		if (setting == 23)
		{
			return @"flux";
		}
		if (setting == 24)
		{
			return @"ssh";
		}
		if (setting == 25)
		{
			return @"wallproxy";
		}
	}
	return nil;
}

-(void)buttonTapped:(UIView*)tapped{
	if (tapped.tag < 6)
	{
		%orig;
	}
	else {
		if (tapped.tag == 6)
		{
			[self _setDataEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 7)
		{
			[self _setLocationEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 8)
		{
			[self _setHotspotEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 9)
		{
			[self _setLock];
		}
		if (tapped.tag == 10)
		{
			[self _setShutdown];
		}
		if (tapped.tag == 11)
		{
			[self _setReboot];
		}
		if (tapped.tag == 12)
		{
			[self _setRespring];
		}
		if (tapped.tag == 13 || tapped.tag == 14 || tapped.tag == 15)
		{
			[self _set3GEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 16)
		{
			[self _setHome];
		}
		if (tapped.tag == 17)
		{
			[self _setVPNEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 18)
		{
			[self _setVibrateEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 19)
		{
			[self _setScreenShot];
		}
		if (tapped.tag == 20)
		{
			[self _setAutoLockEnabled:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 21)
		{
			[self _setKillBackground];
		}
		if (tapped.tag == 22)
		{
			[self _setClearBadge];
		}
		if (tapped.tag == 23)
		{
			[self _setFlux:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 24)
		{
			[self _setSSH:[(UIButton*)tapped isSelected]];
		}
		if (tapped.tag == 25)
		{
			[self _setWP:[(UIButton*)tapped isSelected]];
		}
	}

	if (CCSDismissControlCenter)
	{
		if (tapped.tag != 9 && tapped.tag != 16 && tapped.tag != 19 && tapped.tag != 21)
		{
			[[objc_getClass("SBControlCenterController") sharedInstance] performSelector:@selector(handleMenuButtonTap) withObject:nil afterDelay:0.8f];
		}
	}
}

%new
-(void)handleLongPress:(UILongPressGestureRecognizer *)recognizer{
	switch (recognizer.view.tag) {
        case 1:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=WIFI"] publicURLsOnly:NO];
            break;
        case 2:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=Bluetooth"] publicURLsOnly:NO];
            break;
        case 7:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"] publicURLsOnly:NO];
            break;
        case 16:
        	[[objc_getClass("SBAssistantController") sharedInstance] _activateSiriForPPT];
        	break;
        case 17:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=General&path=VPN"] publicURLsOnly:NO];
            break;
        case 18:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=Sounds"] publicURLsOnly:NO];
            break;
        case 20:
        	[(SpringBoard*)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=General&path=AUTOLOCK"] publicURLsOnly:NO];
        	break;
        default:
            break;
    }
}

-(void)dealloc{
	[self _tearDownData];
	[self _tearDownLocation];
	[self _tearDownHotspot];
	[self _tearDown3G];
	[self _tearDownVibrate];
	if ([self _fluxAvailable])
	{
		[self _tearDownFlux];
	}
	%orig;
}

%new
-(void)_captureButtonForSetting:(int)setting{
	UIView* button = [self _buttonForSetting:setting];
	[(id)button setSelected:NO];
	UIGraphicsBeginImageContext(button.frame.size);
 	[button.layer renderInContext:UIGraphicsGetCurrentContext()]; 
 	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
 	UIGraphicsEndImageContext();

 	NSString* pathToCreate = [NSString stringWithFormat:@"/var/mobile/Library/CCSettings/%@.png",[self _identifierForSetting:setting]];

 	NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
 	[imageData writeToFile:pathToCreate atomically:YES];
}

-(void)viewDidLoad{
	[self _loadSettings];
	lastLockStatus = [(SpringBoard*)[UIApplication sharedApplication] isLocked];
	
	%orig;
	int button = 6;
	do
		[self _addButtonForSetting:button ++];
	while (button != 26);
	
	[self _updateLocationButtonState];
	[self _update3GButtonState];
	if ([self _fluxAvailable])
	{
		[self _updateFluxButtonState];
	}
	[self _updateDataButtonState];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &ccsettingsOrderChanged, CFSTR("com.plipala.ccsettings.orderchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &ccsettingsPreferencesChanged, CFSTR("com.plipala.ccsettings.preferencesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &ccsettingsHideWhenLockedChanged, CFSTR("com.plipala.ccsettings.hideWhenLockedChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &ccsettingsWhiteListChanged, CFSTR("com.plipala.ccsettings.whiteListChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

-(void)viewWillAppear:(BOOL)view{
	BOOL lockedStatus = [(SpringBoard*)[UIApplication sharedApplication] isLocked];
	if (lastLockStatus != lockedStatus && [hideWhenLocked count] > 0)
	{
		lastLockStatus = lockedStatus;
		[self _reloadButtons];
	}

	[(UIScrollView*)[[self view] valueForKey:@"_layview"] setContentOffset:CGPointMake(0,0) animated:NO];
	[self _updateHotspotButtonState];
	[self _updateAutoLockButtonState];
	[(id)self performSelectorOnMainThread:@selector(_updateVPNButtonState) withObject:nil waitUntilDone:NO];
	if ([self _sshAvailable])
	{
		[self _updateSSHButtonStatus];
	}
	[(id)self performSelectorOnMainThread:@selector(_updateWPButtonStatus) withObject:nil waitUntilDone:NO];
}

-(void)_updateMuteButtonState{
	%orig;
	[self _updateVibrateButtonState];
}

%new
-(void)_loadSettings{
	NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.preferences.plist"];
	NSLog(@"settings %@",settings);
	if (settings != nil)
	{
		if ([settings objectForKey:@"TOGGLES_PER_LINE"] != nil)
		{
			CCSTogglePerLine = [[settings objectForKey:@"TOGGLES_PER_LINE"] intValue];
		}
		if ([settings objectForKey:@"DISMISS_CONTROL_CENTER"])
		{
			CCSDismissControlCenter = [[settings objectForKey:@"DISMISS_CONTROL_CENTER"] boolValue];
		}
		if ([settings objectForKey:@"NETWORK_MODE"])
		{
			CCSNetworkMode = [[settings objectForKey:@"NETWORK_MODE"] intValue];
		}
		if ([settings objectForKey:@"KILL_MUSIC"])
		{
			CCSKillMusic = [[settings objectForKey:@"KILL_MUSIC"] boolValue];
		}
		if ([settings objectForKey:@"DISMISS_CONTROL_CENTER_KB"])
		{
			CCSDismissControlCenterKB = [[settings objectForKey:@"DISMISS_CONTROL_CENTER_KB"] boolValue];
		}
		if ([settings objectForKey:@"CLOCK_TYPE"])
		{
			CCSQLClockType = [[settings objectForKey:@"CLOCK_TYPE"] intValue];
		}
	}
}

%new
-(void)_initData{
	id ct = (id)CTTelephonyCenterGetDefault();
	CTTelephonyCenterAddObserver(ct, self, &dataCallback, CFSTR("kCTRegistrationDataStatusChangedNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%new
-(void)_tearDownData{
	id ct = (id)CTTelephonyCenterGetDefault();
	CTTelephonyCenterRemoveObserver(ct, self, CFSTR("kCTRegistrationDataStatusChangedNotification") , NULL);
}

%new
- (BOOL)_getData{
    return CTCellularDataPlanGetIsEnabled();
}

%new
-(void)_setDataEnabled:(BOOL)enabled{
	CTCellularDataPlanSetIsEnabled(enabled);
	NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"CELLULAR_DATA_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"CELLULAR_DATA_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:6]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:6]];
    }
}

%new
-(void)_updateDataButtonState{
	[[self _buttonForSetting:6] setSelected:[self _getData]];
}

%new
-(void)_initLocation{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &locationCallback, CFSTR("com.apple.locationd/Prefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%new
-(void)_tearDownLocation{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, CFSTR("com.apple.locationd/Prefs"), NULL); 
}

%new
-(BOOL)_getLocation{
    return [CLLocationManager locationServicesEnabled];
}

%new
-(void)_setLocationEnabled:(BOOL)enabled{
	[CLLocationManager setLocationServicesEnabled:enabled];
	NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"GPS_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"GPS_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:7]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:7]];
    }
}

%new
-(void)_updateLocationButtonState{
	[[self _buttonForSetting:7] setSelected:[self _getLocation]];
}

static id phController;
static NSBundle *phBundle;
static id phSpecifier;
static NSLock *phReloadLock;

%new
-(void)_initHotspot{
	phBundle = [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/WirelessModemSettings.bundle"] retain];
    [phBundle load];
    %init(WirelessModemController);
    phController = [[[phBundle classNamed:@"WirelessModemController"] alloc] initForContentSize:CGSizeMake(0,0)];
    phSpecifier = [[PSSpecifier preferenceSpecifierNamed:@"Personal Hotspot" target:phController set:@selector(setInternetTethering:specifier:) get:@selector(internetTethering:) detail:Nil cell:PSSwitchCell edit:Nil] retain];
    phReloadLock = [[NSLock alloc] init];
}

%new
-(void)_tearDownHotspot{
	[phReloadLock lock];
	[phBundle unload];
	[phBundle release];
    [phController release];
    [phSpecifier release];
    [phReloadLock unlock];
	[phReloadLock release];
}

%new
-(BOOL)_getHotspot{
	 BOOL enabled = NO;
    if ([phController respondsToSelector:@selector(internetTethering:)]) {
        enabled = [[phController internetTethering:phSpecifier] boolValue];
    }
    return enabled;
}

%new
-(void)_reloadHotspot{
	[phReloadLock lock];
    [phController release];
    [phSpecifier release];
    phController = [[[phBundle classNamed:@"WirelessModemController"] alloc] initForContentSize:CGSizeMake(0,0)];
    phSpecifier = [[PSSpecifier preferenceSpecifierNamed:@"Personal Hotspot" target:phController set:@selector(setInternetTethering:specifier:) get:@selector(internetTethering:) detail:Nil cell:PSSwitchCell edit:Nil] retain];
    [phReloadLock unlock];
}

%new
-(void)_setHotspotEnabled:(BOOL)enabled{
	if (enabled)
	{
		if (![self _getData])
		{
			NSString *title = [localBundle localizedStringForKey:@"PERSONAL_HOTSPOT_DATA_OFF_TITLE" value:@"" table:nil];
        	NSString *message = [localBundle localizedStringForKey:@"PERSONAL_HOTSPOT_DATA_OFF_MESSAGE" value:@"" table:nil];
        	NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"PERSONAL_HOTSPOT_DATA_OFF_CANCEL" value:@"" table:nil];
        	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil] autorelease];
        	[alertView show];
        	[[self _buttonForSetting:8] setSelected:NO];
        	return;
		}
	}
	[self _reloadHotspot];
    if ([phController respondsToSelector:@selector(setInternetTethering:specifier:)]) {
        [phController setInternetTethering:[NSNumber numberWithBool:enabled] specifier:phSpecifier];
    }

    NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"PERSONAL_HOTSPOT_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"PERSONAL_HOTSPOT_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:8]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:8]];
    }

}

%new
-(void)_updateHotspotButtonState{
	[[self _buttonForSetting:8] setSelected:[self _getHotspot]];
}

%new
-(void)_setLock{
   	[(SpringBoard*)[UIApplication sharedApplication] _lockButtonUpFromSource:1];
	[[self _buttonForSetting:9] setSelected:NO];
}

%new
-(void)_setShutdown{
	[[self _buttonForSetting:10] setSelected:NO];
	NSString *message = [localBundle localizedStringForKey:@"SHOTDOWN_MESSAGE" value:@"" table:nil];
    NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"SHOTDOWN_CANCEL" value:@"" table:nil];
    NSString *sureButtonTitle = [localBundle localizedStringForKey:@"SHOTDOWN_SURE" value:@"" table:nil];
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:sureButtonTitle,nil] autorelease];
    alertView.tag = 12306;
    [alertView show];
}

%new
-(void)_setReboot{
	[[self _buttonForSetting:11] setSelected:NO];
	NSString *message = [localBundle localizedStringForKey:@"REBOOT_MESSAGE" value:@"" table:nil];
    NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"REBOOT_CANCEL" value:@"" table:nil];
    NSString *sureButtonTitle = [localBundle localizedStringForKey:@"REBOOT_SURE" value:@"" table:nil];
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:sureButtonTitle,nil] autorelease];
    alertView.tag = 12307;
    [alertView show];
}

%new
-(void)_setRespring{
	[[self _buttonForSetting:12] setSelected:NO];
	NSString *message = [localBundle localizedStringForKey:@"RESPRING_MESSAGE" value:@"" table:nil];
    NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"RESPRING_CANCEL" value:@"" table:nil];
    NSString *sureButtonTitle = [localBundle localizedStringForKey:@"RESPRING_SURE" value:@"" table:nil];
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:sureButtonTitle,nil] autorelease];
    alertView.tag = 12308;
    [alertView show];
}

%new
-(NSDictionary *)_getRATState:(NSDictionary *)stateDictionary{
    static NSDictionary *ratState= nil;
    static NSLock *ratStateLock = nil;
    if (ratStateLock == nil) {
        ratStateLock = [[NSLock alloc] init];
    }
    if (ratState == nil || stateDictionary != nil) {
        NSDictionary *status = nil;
        void *conn;
        NSMutableArray *DataRates; 
        int RATSwitchKind = 0; 
        struct CopyDataInfo info;
        
        int _4GOverride = 0;
        int _RATSwitchKind = 0;
        int _CellularDataPlanGetIsEnabled = 0;
        
        const char* CTSdkPath = "/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony";
        
        void * handle = (int*)dlopen(CTSdkPath, RTLD_LAZY);
        if(handle) {
            if (stateDictionary == nil) {
                void* (*_CTServerConnectionCreate)(CFAllocatorRef allocator,void * callback, int* err);
                *(void **)(&_CTServerConnectionCreate) = (void *)dlsym(handle,"_CTServerConnectionCreate");
                conn = _CTServerConnectionCreate(kCFAllocatorDefault, (void (*))_callback, nil);
                if ( conn )
                {
                    void (*_CTServerConnectionCopyDataStatus)(void *info, void *conn, int value, NSDictionary **status);
                    *(void **)(&_CTServerConnectionCopyDataStatus) = (void *)dlsym(handle,"_CTServerConnectionCopyDataStatus");
                    _CTServerConnectionCopyDataStatus(&info, conn, 0, &status);
                    if (!info.dummy2)
                    {
                        [status autorelease];
                    }
                    CFRelease(conn);
                }
            }
            else {
                status = stateDictionary;
            }
            
            NSMutableArray* (*CTRegistrationCopySupportedDataRates)();
            *(void **)(&CTRegistrationCopySupportedDataRates) = (void *)dlsym(handle,"CTRegistrationCopySupportedDataRates");
            DataRates = CTRegistrationCopySupportedDataRates();
            if(DataRates != nil)
            {
                if( ( [DataRates containsObject: @"kCTRegistrationDataRate3G" ]  & 0xFF )   &&  
                   ( [DataRates containsObject: @"kCTRegistrationDataRate4G" ]  & 0xFF ) ) 
                {
                    RATSwitchKind = 2;
                }
                else if( ([DataRates containsObject: @"kCTRegistrationDataRate2G" ]  & 0xFF )   &&  
                        ([DataRates containsObject: @"kCTRegistrationDataRate3G" ]  & 0xFF ) )
                {
                    RATSwitchKind = 1;
                }
                
                _RATSwitchKind = RATSwitchKind;
                [DataRates release];
            }
            
            if(status)
            {
                if ( [status objectForKey:@"kCTRegistrationDataIndicatorOverride"] )
                {
                    _4GOverride = 1;
                }
                else {
                    _4GOverride = 0;
                }
                
            }
            int (*CTCellularDataPlanGetIsEnabled)();
            *(void **)(&CTCellularDataPlanGetIsEnabled) = (void *)dlsym(handle,"CTCellularDataPlanGetIsEnabled");
            _CellularDataPlanGetIsEnabled = CTCellularDataPlanGetIsEnabled();
        }
        dlclose(handle);
        [ratStateLock lock];
        if (ratState != nil) {
            [ratState release];
        }
        ratState = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_RATSwitchKind],@"RATSwitchKind",[NSNumber numberWithInt:_4GOverride],@"4GOverride",[NSNumber numberWithInt:_CellularDataPlanGetIsEnabled],@"CellularDataPlanGetIsEnabled", nil] retain];
        [ratStateLock unlock];
    }
    return ratState;
}

%new
-(NSString *)_RATModeString
{
	if (CCSNetworkMode == 1)
	{
		return @"3G";
	}
    NSString* RATMode = @"LTE"; 
    NSDictionary *ratState = [self _getRATState:nil];
    int RATSwitchKind = [[ratState objectForKey:@"RATSwitchKind"] intValue]; 
    if ( RATSwitchKind != 2 )
    {
        RATMode = @"";
        
        if(RATSwitchKind == 1 )
        {
            RATMode = @"3G";
            if ( [[ratState objectForKey:@"4GOverride"] intValue] )
                RATMode = @"4G";
        }
    }
    return  RATMode;
}

%new
-(BOOL)_RATSwitchAvailable{
	if (CCSNetworkMode == 1)
	{
		return 1;
	}
    signed int isPhone = 0; 
    int RATSwitchKind; 
    int rtn = 0; 
    
    NSDictionary *ratState = [self _getRATState:nil];
    RATSwitchKind = [[ratState objectForKey:@"RATSwitchKind"] intValue];
    if ( RATSwitchKind == 1 )
    {
        RATSwitchKind = [[ratState objectForKey:@"RATSwitchKind"] intValue];
        if( UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom])
            isPhone = 1;
    }
    
    if ( RATSwitchKind == 2 )
    {

        rtn = [[ratState objectForKey:@"CellularDataPlanGetIsEnabled"] intValue];
        if ( rtn )
            rtn = 1;
        
    }
    
    if ( isPhone )
        rtn = 1;
    
    return rtn;
}

%new
-(BOOL)_get3G{
    BOOL enabled = NO;
    const char* CTSdkPath = "/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony";
    void * handle = (int*)dlopen(CTSdkPath, RTLD_LAZY);
    
    if (handle != nil) {
        int RATSwitchKind;
        RATSwitchKind = [[[self _getRATState:nil] objectForKey:@"RATSwitchKind"] intValue];
        if (CCSNetworkMode == 1)
        {
        	RATSwitchKind = 1;
        }
        
        CFStringRef *kCTRegistrationDataRate2G;
        CFStringRef *kCTRegistrationDataRate3G;
        CFStringRef *kCTRegistrationDataRate4G;
        CFStringRef *kCTRegistrationDataRateUnknown;
        
        kCTRegistrationDataRate2G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate2G");
        kCTRegistrationDataRate3G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate3G");
        kCTRegistrationDataRate4G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate4G");
        kCTRegistrationDataRateUnknown = (CFStringRef *)dlsym(handle,"kCTRegistrationDataRateUnknown");
        
        CFStringRef (*CTRegistrationGetCurrentMaxAllowedDataRate)();
        *(void **)(&CTRegistrationGetCurrentMaxAllowedDataRate) = (void *)dlsym(handle,"CTRegistrationGetCurrentMaxAllowedDataRate");
        
        CFStringRef currentMaxAllowedDataRate = CTRegistrationGetCurrentMaxAllowedDataRate();
        
        if (currentMaxAllowedDataRate != *kCTRegistrationDataRateUnknown) {
            if ((RATSwitchKind == 2 && currentMaxAllowedDataRate == *kCTRegistrationDataRate4G) || (RATSwitchKind == 1 && currentMaxAllowedDataRate == *kCTRegistrationDataRate3G)) {
                enabled = YES;
            }
        }
    }
    dlclose(handle);
 	return enabled;   
}

%new
-(void)_set3GEnabled:(BOOL)enabled{
    const char* CTSdkPath = "/System/Library/PrivateFrameworks/CoreTelephony.framework/CoreTelephony";
    void * handle = (int*)dlopen(CTSdkPath, RTLD_LAZY);
    if (handle != nil) {
        int RATSwitchKind; 
        CFStringRef *firstDataRate; 
        CFStringRef *secordDataRate; 
        CFStringRef tempfirstDataRate; 
        CFStringRef tempsecordDataRate; 
        
        RATSwitchKind = [[[self _getRATState:nil] objectForKey:@"RATSwitchKind"] intValue];
        if (CCSNetworkMode)
        {
        	RATSwitchKind = 1;
        }
        
        CFStringRef *kCTRegistrationDataRate2G;
        CFStringRef *kCTRegistrationDataRate3G;
        CFStringRef *kCTRegistrationDataRate4G;
        CFStringRef *kCTRegistrationDataRateUnknown;
        
        kCTRegistrationDataRate2G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate2G");
        kCTRegistrationDataRate3G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate3G");
        kCTRegistrationDataRate4G = (CFStringRef  *)dlsym(handle,"kCTRegistrationDataRate4G");
        kCTRegistrationDataRateUnknown = (CFStringRef *)dlsym(handle,"kCTRegistrationDataRateUnknown");
        
        if ( 1 == RATSwitchKind )
        {
            firstDataRate = kCTRegistrationDataRate2G;
            secordDataRate = kCTRegistrationDataRate3G;
        }
        else if( 2 == RATSwitchKind )
        {
            firstDataRate = kCTRegistrationDataRate3G;
            if (CCSNetworkMode == 2)
            {
            	firstDataRate = kCTRegistrationDataRate2G;
            }
            secordDataRate = kCTRegistrationDataRate4G;
        }
        
        if (RATSwitchKind == 1 || RATSwitchKind == 2) {
            tempfirstDataRate = *firstDataRate;
            tempsecordDataRate = *secordDataRate;
            
            if(!enabled)
                tempsecordDataRate = tempfirstDataRate;
            
            int (*CTRegistrationSetMaxAllowedDataRate)(CFStringRef DataRateValue);
            *(void **)(&CTRegistrationSetMaxAllowedDataRate) = (void *)dlsym(handle,"CTRegistrationSetMaxAllowedDataRate");
            CTRegistrationSetMaxAllowedDataRate(tempsecordDataRate);
        }
        dlclose(handle);
    }

    NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:[NSString stringWithFormat:@"%@_ON",[self _RATModeString]] value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:[NSString stringWithFormat:@"%@_OFF",[self _RATModeString]] value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:13]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:13]];
    }
}

%new
-(void)_init3G{
	id ct = (id)CTTelephonyCenterGetDefault();
	CTTelephonyCenterAddObserver(ct, self, &registrationDataStatusChanged,CFSTR("kCTRegistrationDataStatusChangedNotification"),NULL,
                                              CFNotificationSuspensionBehaviorCoalesce);
}

%new
-(void)_tearDown3G{
	id ct = (id)CTTelephonyCenterGetDefault();
	CTTelephonyCenterRemoveObserver(ct, self, CFSTR("kCTRegistrationDataStatusChangedNotification") , NULL);
}

%new
-(void)_update3GButtonState{
	NSString *modeSeting = [self _RATModeString];
	if ([modeSeting isEqualToString:@"3G"])
	{
		[[self _buttonForSetting:13] setSelected:[self _get3G]];
	}
	else if ([modeSeting isEqualToString:@"4G"])
	{
		[[self _buttonForSetting:14] setSelected:[self _get3G]];
	}
	else if ([modeSeting isEqualToString:@"LTE"])
	{
		[[self _buttonForSetting:15] setSelected:[self _get3G]];
	}
}

static NSLock *homeMenuLock = nil;
static NSTimer *homeMenuTimer = nil;

%new
-(void)_delayHome{
	[homeMenuLock lock];
	if(homeMenuTimer != nil) {
		[homeMenuTimer release];
    	homeMenuTimer = nil;		
	}
	[homeMenuLock unlock];
	[[self _buttonForSetting:16] setSelected:NO];
	[[objc_getClass("SBUIController") sharedInstance] clickedMenuButton];
	[[objc_getClass("SBControlCenterController") sharedInstance] handleMenuButtonTap];
}

%new
-(void)_setHome{
	if (homeMenuLock == nil)
	{
    	homeMenuLock = [[NSLock alloc] init];
	}
	if (homeMenuTimer == nil) {
        homeMenuTimer = [[NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(_delayHome) userInfo:nil repeats:NO] retain];
    }
    else{
        [homeMenuLock lock];
        if (homeMenuTimer != nil) {
            [homeMenuTimer invalidate];
            [homeMenuTimer release];
            homeMenuTimer = nil;		
        }
        [homeMenuLock unlock];
        [[objc_getClass("SBUIController") sharedInstance] handleMenuDoubleTap];
        [[self _buttonForSetting:16] setSelected:NO];
    }
}

%new
-(void)_initVPN{
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/PreferenceBundles/VPNPreferences.bundle"), kCFURLPOSIXPathStyle, true);
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, url);
    CFRelease(url);
    CFBundleLoadExecutable(bundle);
}

%new
-(BOOL)_getVPN{
	BOOL enabled = NO;
	PrepareVpn();
    VPNConnectionStore *_store;
    object_getInstanceVariable(vpnController,"_store",(void**)&_store);
    [_store reloadVPN];
    if (![_store currentConnection]) {
        return NO;
    }
    PSSpecifier *_vpnSpecifier;
    object_getInstanceVariable(vpnController,"_vpnSpecifier",(void**)&_vpnSpecifier);
    enabled = [[vpnController vpnActiveForSpecifier:_vpnSpecifier] boolValue];
    return enabled;
}

%new
-(void)_setVPNEnabled:(BOOL)enabled{
	PrepareVpn();
    VPNConnectionStore *_store;
    object_getInstanceVariable(vpnController,"_store",(void**)&_store);
    [_store reloadVPN];
    if (![_store currentConnection]) {
    	NSString *title = [localBundle localizedStringForKey:@"VPN_TITLE" value:@"" table:nil];
        NSString *message = [localBundle localizedStringForKey:@"VPN_NO_CONNECTION_MESSAGE" value:@"" table:nil];
        NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"VPN_CANCEL" value:@"" table:nil];
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil] autorelease];
        [alertView show];
        [[self _buttonForSetting:17] setSelected:NO];
        return;
    }
    if ([(VPNConnection*)[_store currentConnection] needsPassword]) {
    	NSString *title = [localBundle localizedStringForKey:@"VPN_TITLE" value:@"" table:nil];
        NSString *message = [localBundle localizedStringForKey:@"VPN_NO_PASSWORD_MESSAGE" value:@"" table:nil];
        NSString *cancelButtonTitle = [localBundle localizedStringForKey:@"VPN_CANCEL" value:@"" table:nil];
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil] autorelease];
        [alertView show];
        [[self _buttonForSetting:17] setSelected:NO];
        return;
    }
    [vpnController _setVPNActive:enabled];

    NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"VPN_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"VPN_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:17]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:17]];
    }
}

%new
-(void)_updateVPNButtonState{
	[[self _buttonForSetting:17] setSelected:[self _getVPN]];
}

%new
-(void)_initVibrate{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &vibrateCallback, CFSTR("com.apple.springboard.silent-vibrate.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &vibrateCallback, CFSTR("com.apple.springboard.ring-vibrate.change"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%new
-(void)_tearDownVibrate{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, CFSTR("com.apple.springboard.silent-vibrate.changed"), NULL);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, CFSTR("com.apple.springboard.ring-vibrate.change"), NULL); 
}

%new
-(BOOL)_getVibrate{
    NSString *getKey = [self _getMuted]?@"silent-vibrate":@"ring-vibrate";
    BOOL res = NO;
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    if(plistDict != nil){
        if ([[plistDict objectForKey:getKey] boolValue]){
            res = YES;
        }
        else{
            res = NO;
        }
    }
    return res;
}

%new
-(void)_setVibrateEnabled:(BOOL)enabled{
    BOOL mute = [self _getMuted];
    NSString *getKey = mute?@"silent-vibrate":@"ring-vibrate";
    NSMutableDictionary *plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    if(plistDict != nil){
        [plistDict setValue:[NSNumber numberWithInt:enabled] forKey:getKey];
        [plistDict writeToFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically: YES];
        GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), (CFStringRef)getKey);
        if (mute) {
            notify_post("com.apple.springboard.silent-vibrate.changed");
        }
        else {
            notify_post("com.apple.springboard.ring-vibrate.change");
        }
    }

    NSString *updateString = nil;
    if (enabled)
    {
    	if (mute)
    	{
    		updateString = [localBundle localizedStringForKey:@"SILENT_VIBRATE_ON" value:@"" table:nil];
    	}
    	else {
    		updateString = [localBundle localizedStringForKey:@"RING_VIBRATE_ON" value:@"" table:nil];
    	}
    	
    }
    else {
    	if (mute)
    	{
    		updateString = [localBundle localizedStringForKey:@"SILENT_VIBRATE_OFF" value:@"" table:nil];
    	}
    	else {
    		updateString = [localBundle localizedStringForKey:@"RING_VIBRATE_OFF" value:@"" table:nil];
    	}
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:18]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:18]];
    }
}

%new
-(void)_updateVibrateButtonState{
	[[self _buttonForSetting:18] setSelected:[self _getVibrate]];
}

%new
-(void)_delayScreenShot{
	[[objc_getClass("SBScreenShotter") sharedInstance] saveScreenshot:YES];
	[[self _buttonForSetting:19] setSelected:NO];
}

%new
-(void)_setScreenShot{
	[[objc_getClass("SBControlCenterController") sharedInstance] handleMenuButtonTap];
	[(id)self performSelector:@selector(_delayScreenShot) withObject:nil afterDelay:0.5f];
}

%new
-(int)_getAutoLock{
	int autoLockTime = -1;
    void *handle = dlopen("/System/Library/PrivateFrameworks/ManagedConfiguration.framework/ManagedConfiguration", RTLD_LAZY);
    if (handle != nil) {
        CFStringRef *pfn = (CFStringRef*)dlsym(handle,"MCFeatureAutoLockTime");
        NSNumber *setting = [[objc_getClass("MCProfileConnection") sharedConnection] effectiveValueForSetting:(id)*pfn];
        if ([setting intValue] - 0x7FFFFFFF != 0) {
            autoLockTime = [setting intValue];
        }
        dlclose(handle);
    }
    return autoLockTime;
}

%new
-(void)_setAutoLockEnabled:(BOOL)enabled{
	int autoLockTime = 60;
	NSNumber *autoLockSetting = [[NSUserDefaults standardUserDefaults] objectForKey:@"CCSettingsAutoLockTime"];
	if (autoLockSetting != nil)
	{
		autoLockTime = [autoLockSetting intValue];
	}
	void *handle = dlopen("/System/Library/PrivateFrameworks/ManagedConfiguration.framework/ManagedConfiguration", RTLD_LAZY);
        
    if (handle != nil) {
        CFStringRef *pfn = (CFStringRef*)dlsym(handle,"MCFeatureAutoLockTime");
        if (pfn != nil) {
            if(enabled){
                NSNumber *num = [NSNumber numberWithInt:autoLockTime];
                [[objc_getClass("MCProfileConnection") sharedConnection] removeValueSetting:(id)*pfn];
                [[objc_getClass("MCProfileConnection") sharedConnection] setValue:num forSetting:(id)*pfn];
                
            }
            else
            {
            	int oldAutoLockTime = [self _getAutoLock];
            	if (oldAutoLockTime > 0)
            	{
            		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:oldAutoLockTime] forKey:@"CCSettingsAutoLockTime"];
            		[[NSUserDefaults standardUserDefaults] synchronize];
            	}
                NSNumber *num = [NSNumber numberWithInt:0x7FFFFFFF];
                [[objc_getClass("MCProfileConnection") sharedConnection] removeValueSetting:(id)*pfn];
                [[objc_getClass("MCProfileConnection") sharedConnection] setValue:num forSetting:(id)*pfn];
            }
        }
        dlclose(handle);
    }

    NSString *updateString = nil;
    if (enabled)
    {
    	int minutes = autoLockTime / 60;
    	if (minutes == 0)
    	{
    		minutes = 1;
    	}
    	if (minutes == 1)
    	{
    		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"AUTO_LOCK_MIN" value:@"" table:nil],minutes];
    	}
    	else {
    		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"AUTO_LOCK_MINS" value:@"" table:nil],minutes];
    	}
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"AUTO_LOCK_NEVER" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:20]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:20]];
    }
}

%new
-(void)_updateAutoLockButtonState{
	[[self _buttonForSetting:20] setSelected:[self _getAutoLock] > 0];
}

%new
-(void)_delayUpdateKillBackgroundButtonState{
	[[self _buttonForSetting:21] setUserInteractionEnabled:YES];
	[[self _buttonForSetting:21] setSelected:NO];
	if (CCSDismissControlCenterKB || CCSDismissControlCenter){
		[[objc_getClass("SBControlCenterController") sharedInstance] performSelector:@selector(handleMenuButtonTap) withObject:nil afterDelay:0.8f];
	}
}

%new
-(void)_setKillBackground{
	[[self _buttonForSetting:21] setUserInteractionEnabled:NO];
	if ([(SpringBoard*)[UIApplication sharedApplication] isLocked])
	{
		NSString *updateString = [localBundle localizedStringForKey:@"KILL_BG_DEVICE_LOCK" value:@"" table:nil];
	    if (objc_getClass("SBControlCenterStatusUpdate"))
	    {
	    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:21]];
	    	[[self delegate] section:self publishStatusUpdate:statusUpdate];
	    }
	    else {
			[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:21]];
	    }   
	    [(id)self performSelector:@selector(_delayUpdateKillBackgroundButtonState) withObject:nil afterDelay:0.3f];
	    return;
	}
	CCSettingsSetDismissLockStatus(1);
	[[objc_getClass("SBUIController") sharedInstance] _activateAppSwitcherFromSide:0];
	id sliderController = [[objc_getClass("SBUIController") sharedInstance] switcherController];
	int i = 0;
	int count = 0;
	NSString *appID = [sliderController _displayIDAtIndex:i];
	id nowPlayingApplication = CCSKillMusic? nil : [[objc_getClass("SBMediaController") sharedInstance] isPlaying] ? [[objc_getClass("SBMediaController") sharedInstance] nowPlayingApplication] : nil;
	id frontMostApplication = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	while (appID != nil) {
		if ([appID isEqualToString:@"com.apple.springboard"])
		{
			i++;
		}
		else if (nowPlayingApplication != nil && [appID isEqualToString:[nowPlayingApplication displayIdentifier]]){
			i++;
		}
		else if (frontMostApplication != nil && [appID isEqualToString:[frontMostApplication displayIdentifier]]){
			i++;
		}
		else if ([[whiteList objectForKey:appID] boolValue]) {
			i++;
		}
		else {
			[sliderController _quitAppAtIndex:i];
			count++;
		}
		appID = [sliderController _displayIDAtIndex:i];
	}
	[[objc_getClass("SBUIController") sharedInstance] dismissSwitcherAnimated:NO];
	if (frontMostApplication == nil)
	{
		[(SpringBoard *)[UIApplication sharedApplication] showSpringBoardStatusBar];
	}
	CCSettingsSetDismissLockStatus(0);
	NSString *updateString = nil;
	if (count > 1)
	{
		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"KILL_BG_APPS" value:@"" table:nil],count];
	}
	else {
		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"KILL_BG_APP" value:@"" table:nil],count];
	}
    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:21]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:21]];
    }
    
    [(id)self performSelector:@selector(_delayUpdateKillBackgroundButtonState) withObject:nil afterDelay:0.3f];
}

%new
-(void)_delayUpdateClearBadgeButton{
	[[self _buttonForSetting:22] setUserInteractionEnabled:YES];
	[[self _buttonForSetting:22] setSelected:NO];
}

%new
-(void)_setClearBadge{
	[[self _buttonForSetting:22] setUserInteractionEnabled:NO];
	id _iconModel = [[objc_getClass("SBIconController") sharedInstance] valueForKey:@"_iconModel"];
	int count = 0;
	if (_iconModel)
	{
		for (SBApplication *app in [[_iconModel leafIcons] allObjects]) {
			if ([app badgeNumberOrString] != nil)
			{
				[app setBadge:nil];
				count ++;
			}
		}
	}
	NSString *updateString = nil;
	if (count > 1)
	{
		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"CLEAR_BADGE_BADGES" value:@"" table:nil],count];
	}
	else {
		updateString = [NSString stringWithFormat:[localBundle localizedStringForKey:@"CLEAR_BADGE_BADGE" value:@"" table:nil],count];
	}
    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:22]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:22]];
    }
    
    [(id)self performSelector:@selector(_delayUpdateClearBadgeButton) withObject:nil afterDelay:0.3f];
}

%new
-(BOOL)_fluxAvailable{
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/libexec/flux"];
}

%new
-(void)_initFlux{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &fluxCallback, CFSTR("org.herf.flux-enable"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%new
-(void)_tearDownFlux{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, CFSTR("org.herf.flux-enable"), NULL); 
}

%new
-(BOOL)_getFlux{
	NSDictionary *preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.herf.flux.plist"];
	return [[preferencesDictionary objectForKey:@"enable"] boolValue];
}

%new
-(void)_setFlux:(BOOL)enabled{
	NSMutableDictionary *preferencesDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.herf.flux.plist"];
	[preferencesDictionary setObject:[NSNumber numberWithBool:enabled] forKey:@"enable"];
	[preferencesDictionary writeToFile:@"/var/mobile/Library/Preferences/org.herf.flux.plist" atomically:YES];
	notify_post("org.herf.flux-enable");
	NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"FLUX_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"FLUX_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:23]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:23]];
    }
}

%new
-(void)_updateFluxButtonState{
	[[self _buttonForSetting:23] setSelected:[self _getFlux]];
}

%new
-(BOOL)_sshAvailable{
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/ccsettingssupport"] && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchDaemons/com.openssh.sshd.plist"];
}

%new
-(BOOL)_getSSH{
	BOOL status = NO;
	notify_post("com.ccsettings.ssh.status");
	usleep(100);
	NSString *string = [NSString stringWithContentsOfFile:@"/tmp/sshstatus" encoding:NSUTF8StringEncoding error:nil];
	if (string != nil && [string intValue] > 0)
	{
		status = YES;
	}
	return status;
}

%new
-(void)_setSSH:(BOOL)enabled{
	if (enabled)
	{
		notify_post("com.ccsettings.ssh.on");
	}
	else 
	{
		notify_post("com.ccsettings.ssh.off");
	}
	NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"SSH_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"SSH_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:24]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:24]];
    }
}

%new
-(void)_backgroundUpdateSSHButtonStatus{
	BOOL status = [self _getSSH];
	[(id)self performSelectorOnMainThread:@selector(_setSSHButtonStatus:) withObject:[NSNumber numberWithInt:status] waitUntilDone:YES];
}

%new
-(void)_setSSHButtonStatus:(NSNumber *)enabled{
	[[self _buttonForSetting:24] setSelected:[enabled intValue]];
}

%new
-(void)_updateSSHButtonStatus{
	[(id)self performSelectorInBackground:@selector(_backgroundUpdateSSHButtonStatus) withObject:nil];
}

%new
-(BOOL)_wpAvaiable{
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/ccsettingssupport"] && [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/LaunchDaemons/agae.wallproxy.plist"];
}

%new
-(BOOL)_getWP{
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/log/wallproxy.log"];
}

%new
-(void)_setWP:(BOOL)enabled{
	if (enabled)
	{
		notify_post("com.ccsettings.wp.on");
	}
	else 
	{
		notify_post("com.ccsettings.wp.off");
	}
	NSString *updateString = nil;
    if (enabled)
    {
    	updateString = [localBundle localizedStringForKey:@"WP_ON" value:@"" table:nil];
    }
    else {
    	updateString = [localBundle localizedStringForKey:@"WP_OFF" value:@"" table:nil];
    }

    if (objc_getClass("SBControlCenterStatusUpdate"))
    {
    	id statusUpdate = [objc_getClass("SBControlCenterStatusUpdate") statusUpdateWithString:updateString reason:[self _identifierForSetting:25]];
    	[[self delegate] section:self publishStatusUpdate:statusUpdate];

    }
    else {
		[[self delegate] section:self updateStatusText:updateString reason:[self _identifierForSetting:25]];
    }
}

%new
-(void)_updateWPButtonStatus{
	[[self _buttonForSetting:25] setSelected:[self _getWP]];
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (alertView.tag == 12306)
	{
		if (buttonIndex != [alertView cancelButtonIndex]) {
        	[(SpringBoard*)[UIApplication sharedApplication] powerDown];
    	}
	}
	if (alertView.tag == 12307)
	{
		if (buttonIndex != [alertView cancelButtonIndex]) {
        	[(SpringBoard*)[UIApplication sharedApplication] reboot];
    	}
	}
	if (alertView.tag == 12308)
	{
		if (buttonIndex != [alertView cancelButtonIndex]) {
        	[(SpringBoard*)[UIApplication sharedApplication] relaunchSpringBoard];
    	}
	}
}

%end

/*
static id _homeButton = nil;
static id _lockButton = nil;
static id _screenShotButton = nil;
static NSMutableArray *_buttonIdentifiers = nil;

%hook SBCCQuickLaunchSectionController

%new
-(NSNumber *)_orderForIdentifier:(NSString *)identifier{
	if ([orderQuickSetting objectForKey:identifier])
	{
		return [NSNumber numberWithInteger:[[orderQuickSetting objectForKey:identifier] intValue]];
	}
	else {
		return [NSNumber numberWithInteger:-1];
	}
}

%new
-(void)_reloadButtons{
	[[self view] removeAllButtons];
	for (NSString *identifier in [orderQuickSetting allKeys]){
		id theButton = nil;
		if ([identifier isEqualToString:@"torch"])
		{
			theButton = [(id)self valueForKey:@"_torchButton"];
		}
		else if ([identifier isEqualToString:@"clock"])
		{
			theButton = [(id)self valueForKey:@"_clockButton"];
		}
		else if ([identifier isEqualToString:@"calculator"])
		{
			theButton = [(id)self valueForKey:@"_calculatorButton"];
		}
		else if ([identifier isEqualToString:@"camera"])
		{
			theButton = [(id)self valueForKey:@"_cameraButton"];
		}
		else if ([identifier isEqualToString:@"home"]) {
			theButton = _homeButton;
		}
		else if ([identifier isEqualToString:@"lock"]) {
			theButton = _lockButton;
		}
		else if ([identifier isEqualToString:@"screenShot"]) {
			theButton = _screenShotButton;
		}
		else {
			UIImage *buttonImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/CCSettings/QuickLaunch/%@@2x.png",identifier]];
			theButton = [objc_getClass("SBControlCenterButton") roundRectButtonWithGlyphImage:buttonImage];
			[theButton setDelegate:self];
			[(UIButton*)theButton setSelected:NO];
			[(UIButton*)theButton setTag:[_buttonIdentifiers count] + 1];
			[_buttonIdentifiers addObject:identifier];
			NSMutableArray* __buttons =  (NSMutableArray*)[(id)self valueForKey:@"_buttons"];
			[__buttons addObject:theButton];
		}
		if (theButton != nil)
		{
			NSNumber *order = [self _orderForIdentifier:identifier];
			if ([order intValue] < 0)
			{
				[[self view] removeButton:theButton];
			}
			else {
				[theButton setSortKey:order];
				[(id)[self view] addButton:theButton];
			}
		}
	}
}

-(id)init{
	id res = %orig;
	_buttonIdentifiers = [[NSMutableArray alloc] init];
	return res;
}

-(void)dealloc{
	[_buttonIdentifiers release];
	%orig;
}

-(void)viewDidLoad{
	%orig;
	for (NSString *identifier in [orderQuickSetting allKeys]){
		id theButton = nil;
		if ([identifier isEqualToString:@"torch"])
		{
			theButton = [(id)self valueForKey:@"_torchButton"];
		}
		else if ([identifier isEqualToString:@"clock"])
		{
			theButton = [(id)self valueForKey:@"_clockButton"];
		}
		else if ([identifier isEqualToString:@"calculator"])
		{
			theButton = [(id)self valueForKey:@"_calculatorButton"];
		}
		else if ([identifier isEqualToString:@"camera"])
		{
			theButton = [(id)self valueForKey:@"_cameraButton"];
		}
		else if ([identifier isEqualToString:@"home"]) {
			UIImage *buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphQuickHome.png"];
			_homeButton = [objc_getClass("SBControlCenterButton") roundRectButtonWithGlyphImage:buttonImage];
			[_homeButton setDelegate:self];
			[(UIButton*)_homeButton setSelected:NO];
			NSMutableArray* __buttons =  (NSMutableArray*)[(id)self valueForKey:@"_buttons"];
			[__buttons addObject:_homeButton];
			theButton = _homeButton;
		}
		else if ([identifier isEqualToString:@"lock"]) {
			UIImage *buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphQuickLock.png"];
			_lockButton = [objc_getClass("SBControlCenterButton") roundRectButtonWithGlyphImage:buttonImage];
			[_lockButton setDelegate:self];
			[(UIButton*)_lockButton setSelected:NO];
			NSMutableArray* __buttons =  (NSMutableArray*)[(id)self valueForKey:@"_buttons"];
			[__buttons addObject:_lockButton];
			theButton = _lockButton;
		}
		else if ([identifier isEqualToString:@"screenShot"]) {
			UIImage *buttonImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CCSettings/ControlCenterGlyphQuickScreenShot.png"];
			_screenShotButton = [objc_getClass("SBControlCenterButton") roundRectButtonWithGlyphImage:buttonImage];
			[_screenShotButton setDelegate:self];
			[(UIButton*)_screenShotButton setSelected:NO];
			NSMutableArray* __buttons =  (NSMutableArray*)[(id)self valueForKey:@"_buttons"];
			[__buttons addObject:_screenShotButton];
			theButton = _screenShotButton;
		}
		else {
			UIImage *buttonImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/CCSettings/QuickLaunch/%@@2x.png",identifier]];
			theButton = [objc_getClass("SBControlCenterButton") roundRectButtonWithGlyphImage:buttonImage];
			[theButton setDelegate:self];
			[(UIButton*)theButton setSelected:NO];
			[(UIButton*)theButton setTag:[_buttonIdentifiers count] + 1];
			[_buttonIdentifiers addObject:identifier];
			NSMutableArray* __buttons =  (NSMutableArray*)[(id)self valueForKey:@"_buttons"];
			[__buttons addObject:theButton];
		}
		if (theButton != nil)
		{
			NSNumber *order = [self _orderForIdentifier:identifier];
			if ([order intValue] < 0)
			{
				[[self view] removeButton:theButton];
			}
			else {
				[theButton setSortKey:order];
				[(id)[self view] addButton:theButton];
			}
		}
	}
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, &ccsettingsQuickOrderChanged, CFSTR("com.plipala.ccsettings.quick.orderchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

-(void)buttonTapped:(id)tapped{
	if (tapped == [(id)self valueForKey:@"_torchButton"] || tapped == [(id)self valueForKey:@"_clockButton"] || tapped == [(id)self valueForKey:@"_calculatorButton"] || tapped == [(id)self valueForKey:@"_cameraButton"])
	{
		%orig;
	}
	else if (tapped == _homeButton)
	{
		[self _setHome];
	}
	else if (tapped == _lockButton) {
		[self _setLock];
	}
	else if (tapped == _screenShotButton) {
		[self _setScreenShot];
	}
	else {
		%orig;
	}
}

-(id)_urlForButton:(id)button{
	if (button == [(id)self valueForKey:@"_clockButton"])
	{
		if (CCSQLClockType == 0)
		{
			return [NSURL URLWithString:@"clock-worldclock:default"];
		}
		else if (CCSQLClockType == 1)
		{
			return [NSURL URLWithString:@"clock-alarm:default"];
		}
		else if (CCSQLClockType == 2)
		{
			return [NSURL URLWithString:@"clock-stopwatch:default"];
		}
		else {
			return %orig;
		}
	}
	else if (button == [(id)self valueForKey:@"_torchButton"] || button == [(id)self valueForKey:@"_calculatorButton"] || button == [(id)self valueForKey:@"_cameraButton"])
	{
		return %orig;
	}
	else {
		return NULL;
	}
}

-(id)_bundleIDForButton:(id)button{
	if (button == [(id)self valueForKey:@"_torchButton"] || button == [(id)self valueForKey:@"_clockButton"] || button == [(id)self valueForKey:@"_calculatorButton"] || button == [(id)self valueForKey:@"_cameraButton"])
	{
		return %orig;
	}
	else {
		int index = [button tag] - 1;
		if (index < 0 && index >= [_buttonIdentifiers count])
		{
			return nil;
		}
		return [_buttonIdentifiers objectAtIndex:index];
	}
}

+(id)viewClass{
	return objc_getClass("SBCCButtonLayoutScrollViewForQuickSection");
}

-(void)viewWillAppear:(BOOL)view{
	[(UIScrollView*)[[self view] valueForKey:@"_layview"] setContentOffset:CGPointMake(0,0) animated:NO];
}

%new
-(void)_delayHome{
	[homeMenuLock lock];
	if(homeMenuTimer != nil) {
		[homeMenuTimer release];
    	homeMenuTimer = nil;		
	}
	[homeMenuLock unlock];
	[_homeButton setSelected:NO];
	[[objc_getClass("SBUIController") sharedInstance] clickedMenuButton];
	[[objc_getClass("SBControlCenterController") sharedInstance] handleMenuButtonTap];
}

%new
-(void)_setHome{
	if (homeMenuLock == nil)
	{
    	homeMenuLock = [[NSLock alloc] init];
	}
	if (homeMenuTimer == nil) {
        homeMenuTimer = [[NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(_delayHome) userInfo:nil repeats:NO] retain];
    }
    else{
        [homeMenuLock lock];
        if (homeMenuTimer != nil) {
            [homeMenuTimer invalidate];
            [homeMenuTimer release];
            homeMenuTimer = nil;		
        }
        [homeMenuLock unlock];
        [[objc_getClass("SBUIController") sharedInstance] handleMenuDoubleTap];
        [_homeButton setSelected:NO];
    }
}

%new
-(void)_setLock{
   	[(SpringBoard*)[UIApplication sharedApplication] _lockButtonUpFromSource:1];
	[_lockButton setSelected:NO];
}

%new
-(void)_delayScreenShot{
	[[objc_getClass("SBScreenShotter") sharedInstance] saveScreenshot:YES];
	[_screenShotButton setSelected:NO];
}

%new
-(void)_setScreenShot{
	[[objc_getClass("SBControlCenterController") sharedInstance] handleMenuButtonTap];
	[(id)self performSelector:@selector(_delayScreenShot) withObject:nil afterDelay:0.5f];
}

%end
*/

%ctor{
	%init();
	localBundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/CCSettings/Localized.bundle"];
	orderSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.plist"];
	if (orderSetting == nil)
	{
		orderSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/Application Support/CCSettings/CCSettingsOrder.plist"];
	}

	orderQuickSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.quick.plist"];
	if (orderQuickSetting == nil)
	{
		orderQuickSetting = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/Application Support/CCSettings/CCSettingsOrderQuick.plist"];
	}

	hideWhenLocked = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.hidewhenlocked.plist"];
	if (hideWhenLocked == nil)
	{
		hideWhenLocked = [[NSDictionary alloc] init];
	}
	whiteList = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.plipala.ccsettings.whitelist.plist"];
	if (whiteList == nil)
	{
		whiteList = [[NSDictionary alloc] init];
	}
	void *ctlib = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
    if (ctlib) {
        CTTelephonyCenterGetDefault = (CFNotificationCenterRef (*)())dlsym(ctlib, "CTTelephonyCenterGetDefault");
        CTTelephonyCenterAddObserver = (void (*)(id, id, CFNotificationCallback, CFStringRef, const void *, CFNotificationSuspensionBehavior))dlsym(ctlib, "CTTelephonyCenterAddObserver");
        CTTelephonyCenterRemoveObserver = (void (*)(id, id, CFStringRef, const void *))dlsym(ctlib, "CTTelephonyCenterRemoveObserver");
        CTCellularDataPlanGetIsEnabled = (Boolean (*)())dlsym(ctlib, "CTCellularDataPlanGetIsEnabled");
        CTCellularDataPlanSetIsEnabled = (void (*)(Boolean))dlsym(ctlib, "CTCellularDataPlanSetIsEnabled");
    }
    dlclose(ctlib);

    void *gslib = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices", RTLD_LAZY);
    if (gslib)
    {
    	GSSendAppPreferencesChanged = (void (*)(CFStringRef, CFStringRef))dlsym(gslib,"GSSendAppPreferencesChanged");
    }
    dlclose(gslib);
}