#import "UIToggle.h"
#import "substrate.h"
#import <GraphicsServices/GraphicsServices.h>
#import "MediaPlayer/MediaPlayer.h"

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

@interface UIToggleContr : NSObject  <UIActionSheetDelegate> {
	UIActionSheet *alert;
}
-(void)respring;
@end
@implementation UIToggleContr
-(void)popup{
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
- (void)sliderAction:(UISlider*)arg1 {
	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.apple.springboard.plist"];
	[plistDict setValue:[NSNumber numberWithFloat:[arg1 value]] forKey:@"SBBacklightLevel2"];
	[plistDict writeToFile:@"/private/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically: YES];
	GSEventSetBacklightLevel([arg1 value]);
}

-(void)respring {
	exit(0);
}
-(void)wifi
{
	Class SBWiFiManager = objc_getClass("SBWiFiManager");
	[[SBWiFiManager sharedInstance]setWiFiEnabled:![[SBWiFiManager sharedInstance] wiFiEnabled]];
	[[SBWiFiManager sharedInstance] _askToJoinWithID:0];
}
-(void)popupv{
        Class UISettingsToggleController = objc_getClass("UISettingsToggleController");
        alert=[[UIActionSheet alloc] initWithTitle:@"Volume\n\n" delegate:self cancelButtonTitle:@"Done" destructiveButtonTitle:nil otherButtonTitles: nil];
	[alert showInView:MSHookIvar<UIView*>([UISettingsToggleController sharedController], "toggleWindow")];
	MPVolumeView *slider = [[[MPVolumeView alloc] initWithFrame:CGRectMake(60.0, 30.0, 200.0, 10.0)] autorelease];
	[slider sizeToFit];
	[alert addSubview:slider];
}
@end
%ctor {
	id tcont=[UIToggleContr new];
	UISettingsToggleController* handler=[objc_getClass("UISettingsToggleController") sharedController];
        [handler createToggleWithTitle:@"Respring" andImage:@"/Library/UISettings/Icons/respring.png" andSelector:@selector(respring) toTarget:tcont];
        [handler createToggleWithTitle:@"WiFi" andImage:@"/Library/UISettings/Icons/wifi.png" andSelector:@selector(wifi) toTarget:tcont];
        [handler createToggleWithTitle:@"Brightness" andImage:@"/Library/UISettings/Icons/brightness.png" andSelector:@selector(popup) toTarget:tcont];
        [handler createToggleWithTitle:@"Volume" andImage:@"/Library/UISettings/Icons/sound.png" andSelector:@selector(popupv) toTarget:tcont];
}

