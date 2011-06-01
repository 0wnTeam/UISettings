#import "UIToggle.h"
#import "substrate.h"
#import <GraphicsServices/GraphicsServices.h>
#import "MediaPlayer/MediaPlayer.h"
static id wifi_on=nil;
static id wifi_off=nil;
static id airplane_on=nil;
static id airplane_off=nil;
void refresh_(__CFNotificationCenter* b, void* c, const __CFString* d, const void* e, const __CFDictionary* a);
void refresh();
@class SBPowerDownView;

@interface SpringBoard {}
+(id)sharedBoard;
@end
@interface SBTelephonyManager {}
+ (id)sharedTelephonyManager;
- (void)setIsInAirplaneMode:(BOOL)fp8;
- (BOOL)isInAirplaneMode;
+ (id)sharedTelephonyManagerCreatingIfNecessary:(BOOL)fp8;
- (void)updateAirplaneMode;
- (void)airplaneModeChanged;
@end
@interface SBPowerDownController : NSObject
{
    int _count;
    id _delegate;
    SBPowerDownView *_powerDownView;
    BOOL _isFront;
}

+ (id)sharedInstance;
- (void)dealloc;
- (double)autoLockTime;
- (BOOL)isOrderedFront;
- (void)orderFront;
- (void)orderOut;
- (id)powerDownViewWithSize:(struct CGSize)fp8;
- (void)activate;
- (void)_restoreIconListIfNecessary;
- (void)deactivate;
- (id)alertDisplayViewWithSize:(struct CGSize)fp8;
- (void)alertDisplayWillBecomeVisible;
- (void)setDelegate:(id)fp8;
- (void)powerDown;
- (void)cancel;

@end

@interface SBWiFiManager : NSObject {
}
+(id)sharedInstance;
-(id)init;
-(void)scan;
-(BOOL)joining;
-(BOOL)wiFiEnabled;
-(void)setWiFiEnabled:(BOOL)enabled;
-(int)signalStrengthBars;
-(int)signalStrengthRSSI;
-(void)updateSignalStrength;
-(void)_updateSignalStrengthTimer;
-(void)cancelTrust:(BOOL)trust;
-(void)acceptTrust:(id)trust;
-(void)cancelPicker:(BOOL)picker;
-(void)userChoseNetwork:(id)network;
-(id)knownNetworks;
-(void)resetSettings;
-(void)_scanComplete:(CFArrayRef)complete;
-(void)joinNetwork:(id)network password:(id)password;
-(void)_askToJoinWithID:(unsigned)anId;
@end
@interface SBBrightnessController : NSObject {
	BOOL _debounce;
}
+(id)sharedBrightnessController;
-(float)_calcButtonRepeatDelay;
-(void)adjustBacklightLevel:(BOOL)level;
-(void)_setBrightnessLevel:(float)level showHUD:(BOOL)hud;
-(void)setBrightnessLevel:(float)level;
-(void)increaseBrightnessAndRepeat;
-(void)decreaseBrightnessAndRepeat;
-(void)handleBrightnessEvent:(GSEventRef)event;
-(void)cancelBrightnessEvent;
@end
static id airplane=nil;
static id wifi=nil;
@interface UIToggleContr : NSObject  <UIActionSheetDelegate> {
	UIActionSheet *alert;
}
-(void)respring;
@end
@implementation UIToggleContr
-(void)popup
{
	Class UISettingsToggleController = objc_getClass("UISettingsToggleController");
	alert=[[UIActionSheet alloc] initWithTitle:@"Brightness\n\n" delegate:self cancelButtonTitle:@"Done" destructiveButtonTitle:nil otherButtonTitles: nil];
	[alert showInView:MSHookIvar<UIView*>([UISettingsToggleController sharedController], "toggleWindow")];
	CGRect frame = CGRectMake((alert.frame.size.height/2), 30.0, 200.0, 10.0);
	UISlider *slider = [[UISlider alloc] initWithFrame:frame];
	[slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	[slider setBackgroundColor:[UIColor clearColor]];
	slider.minimumValue = 0.0f;
	slider.maximumValue = 1.0f;
	slider.continuous = YES;
	NSNumber *bl = (NSNumber*) CFPreferencesCopyAppValue(CFSTR("SBBacklightLevel2" ), CFSTR("com.apple.springboard"));
	slider.value = [bl floatValue];
	[alert addSubview:slider];

}
- (void)sliderAction:(UISlider*)arg1
{
	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	[plistDict setValue:[NSNumber numberWithFloat:[arg1 value]] forKey:@"SBBacklightLevel2"];
	[plistDict writeToFile:@"/private/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically: YES];
	//GSEventSetBacklightLevel([arg1 value]);
	[[objc_getClass("SBBrightnessController") sharedBrightnessController] _setBrightnessLevel:[arg1 value] showHUD:YES];
}

-(void)respring
{
	exit(0);
}
-(void)wifi
{
	Class SBWiFiManager = objc_getClass("SBWiFiManager");
	BOOL wistatus=![[SBWiFiManager sharedInstance] wiFiEnabled];
	[[SBWiFiManager sharedInstance]setWiFiEnabled:wistatus];
	refresh();
	[[SBWiFiManager sharedInstance] _askToJoinWithID:0];
}
-(void)popupv
{
        Class UISettingsToggleController = objc_getClass("UISettingsToggleController");
        alert=[[UIActionSheet alloc] initWithTitle:@"Volume\n\n" delegate:self cancelButtonTitle:@"Done" destructiveButtonTitle:nil otherButtonTitles: nil];
	[alert showInView:MSHookIvar<UIView*>([UISettingsToggleController sharedController], "toggleWindow")];
	MPVolumeView *slider = [[[MPVolumeView alloc] initWithFrame:CGRectMake(60.0, 30.0, 200.0, 10.0)] autorelease];
	[slider sizeToFit];
	[alert addSubview:slider];
}
-(void)airplane
{
        BOOL airstatus=![[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] isInAirplaneMode];
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] setIsInAirplaneMode:airstatus];
        if(airstatus){
                [airplane setImage:airplane_on forState:UIControlStateNormal];
        } else {
                [airplane setImage:airplane_off forState:UIControlStateNormal];
        }
	refresh();
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] airplaneModeChanged];
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] updateAirplaneMode];
}
-(void)shut
{
	[[objc_getClass("SpringBoard") sharedBoard] powerDown];
}
-(void)reboot
{
        [[objc_getClass("SpringBoard") sharedBoard] reboot];
}
@end
%ctor {
	id tcont=[UIToggleContr new];
	UISettingsToggleController* handler=[objc_getClass("UISettingsToggleController") sharedController];
        [handler createToggleWithTitle:@"Respring" andImage:@"/Library/UISettings/Icons/respring.png" andSelector:@selector(respring) toTarget:tcont];
        wifi=[handler createToggleWithAction:@selector(wifi) title:nil target:tcont];
        [handler createLabelForButton:wifi text:@"WiFi"];
        BOOL wistatus=[[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled];
        NSData *imageData = [NSData dataWithContentsOfFile:@"/Library/UISettings/Icons/wifi.png"];
        wifi_on = [[UIImage imageWithData:imageData] retain];
        imageData = [NSData dataWithContentsOfFile:@"/Library/UISettings/Icons/no_wifi.png"];
	wifi_off = [[UIImage imageWithData:imageData] retain];
        if(wistatus){
                [wifi setImage:wifi_on forState:UIControlStateNormal];
        } else {
                [wifi setImage:wifi_off forState:UIControlStateNormal];
        }
	airplane=[handler createToggleWithAction:@selector(airplane) title:nil target:tcont];
	[handler createToggleWithTitle:@"Brightness" andImage:@"/Library/UISettings/Icons/brightness.png" andSelector:@selector(popup) toTarget:tcont];
        [handler createToggleWithTitle:@"Volume" andImage:@"/Library/UISettings/Icons/sound.png" andSelector:@selector(popupv) toTarget:tcont];
	[handler createToggleWithTitle:@"Power Off" andImage:@"/Library/UISettings/Icons/shutoff.png" andSelector:@selector(shut) toTarget:tcont];
	[handler createToggleWithTitle:@"Reboot" andImage:@"/Library/UISettings/Icons/reboot.png" andSelector:@selector(reboot) toTarget:tcont];
	[handler createToggleWithTitle:@"Safe Mode" andImage:@"/Library/UISettings/Icons/safemode.png" andSelector:@selector(safemode) toTarget:tcont];
	[handler createLabelForButton:airplane text:@"Airplane"];
        imageData = [NSData dataWithContentsOfFile:@"/Library/UISettings/Icons/airplane.png"];
        airplane_on = [[UIImage imageWithData:imageData] retain];
        imageData = [NSData dataWithContentsOfFile:@"/Library/UISettings/Icons/no_airplane.png"];
	airplane_off = [[UIImage imageWithData:imageData] retain];
	BOOL airstatus=[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] isInAirplaneMode];
        if(airstatus){
                [airplane setImage:airplane_on forState:UIControlStateNormal];
        } else {
                [airplane setImage:airplane_off forState:UIControlStateNormal];
        }
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, &refresh_, CFSTR("com.qwerty.uisettings.reload"), NULL, 0);
}

void refresh_(__CFNotificationCenter* b, void* c, const __CFString* d, const void* e, const __CFDictionary* a)
{
refresh();
}
void refresh()
{
        BOOL airstatus=[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] isInAirplaneMode];
        BOOL wistatus=[[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled];
        if(wistatus){
                [wifi setImage:wifi_on forState:UIControlStateNormal];
        } else {
                [wifi setImage:wifi_off forState:UIControlStateNormal];
        }
        if(airstatus){
                [airplane setImage:airplane_on forState:UIControlStateNormal];
        } else {
                [airplane setImage:airplane_off forState:UIControlStateNormal];
        }
}
