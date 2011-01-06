#define hook(x, y) MSHookIvar<id>(x, y);
//Hai, SpringBoard.
#import <dlfcn.h>
#import <SpringBoard/SpringBoard.h>
#include "substrate.h"
#define kHookVer "0.2"
%hook SBNowPlayingBar
static SBNowPlayingBar* sharedSelf = nil;
%new(::)
+(SBNowPlayingBar*)sharedSelf {
	if(sharedSelf == nil) {
		NSLog(@"[UIHook:%s] Error.", kHookVer);
		return nil;
	}
	return sharedSelf;
}
%end

@interface Core : NSObject {
	void* handler;
}
-(void*)coreIfOpen;
-(Class)CoreClass;
-(Core*)initWithPath:(NSString*)path;
@end
@implementation Core
-(Core*)initWithPath:(NSString*)path
{
	handler = dlopen([path UTF8String], RTLD_LOCAL);
	if (!handler) {
		NSLog(@"[UIHook:%s] Error hooking Core: %s", kHookVer, dlerror());
		return nil;
	}
	return self;
}
-(Class)CoreClass
{
	return objc_getClass("UISettingsCore");
}
-(void*)coreIfOpen {
	if (!handler) {
		NSLog(@"[UIHook:%s] Warning: Core isn't open", kHookVer);
		return nil;
	}
	return handler;
}
@end


@interface Hook : NSObject {
	UIButton* triggerButton;
	UIView* contentView;
	SBIconLabel* label;
}
+(Hook*)sharedHook;
-(Hook*)initWithButton:(UIButton*)btn andView:(UIView*)view andIconLabel:(SBIconLabel*)label;
@end

@implementation Hook
static Hook* sHook=nil;
+(Hook*)sharedHook
{
	if (sHook==nil) {
		NSLog(@"[UIHook:%s] Warning: returning nil Hook controller", kHookVer);
	}
    return sHook;
}
-(Hook*)init {
	[super init];
	sHook=self;
	return self;
}
-(Hook*)initWithButton:(UIButton*)btn andView:(UIView*)view andIconLabel:(SBIconLabel*)lbl
{
	[super init];
	sHook=self;
	triggerButton=btn;
	if (triggerButton==nil) {
		NSLog(@"[UIHook:%s] Warning: TriggerButton is nil", kHookVer);
	}	
	contentView=view;
	if (contentView==nil) {
		NSLog(@"[UIHook:%s] Warning: ContentView is nil", kHookVer);
	}		
	label=lbl;
	if (label==nil) {
		NSLog(@"[UIHook:%s] Warning: Label is nil", kHookVer);
	}
	return self;
}
-(void)hook
{
	Core* SettingsHandler=[[Core alloc] initWithPath:@"/Library/UISettings/UICore/UICore.dylib"];
	NSLog(@"Core bootstrapped");
	Class UISettingsCore=[SettingsHandler CoreClass];
	if (!UISettingsCore) {
		NSLog(@"Fail loading UISettings's main class");
	}
	[triggerButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
	[triggerButton addTarget:[UISettingsCore sharedSettings] action:@selector(hook:) forControlEvents:UIControlEventTouchUpInside];
	UILongPressGestureRecognizer *longPressGR;
	longPressGR = [[ UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	longPressGR.delegate = self;
	longPressGR.minimumPressDuration = 1.0;
	[triggerButton addGestureRecognizer:longPressGR];	
}
-(void) handleLongPress:(UILongPressGestureRecognizer *)recognizer  {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		Class SBNowPlayingBar = objc_getClass("SBNowPlayingBar");
		[label setHidden:NO]; // a
		[[SBNowPlayingBar sharedSelf] performSelector:@selector(_orientationLockHit:) withObject:nil];
	}	
}
@end



// OldHookz
%ctor {
NSLog(@"UISettingsV2 - based on nothing");
NSLog(@"(c) 2010 Maximus and qwertyoruiop");
}
%hook SBNowPlayingBarView
static SBNowPlayingBarView* staticSelf = nil;
%new(:)
+(SBNowPlayingBarView*)sharedControlInstance {
	return staticSelf;
}
// selfHook
-(id)initWithFrame:(CGRect)frame {
	staticSelf=self;
	return %orig;
}
%end
%hook SBNowPlayingBarMediaControlsView
static SBNowPlayingBarMediaControlsView* containerSingleton = nil;
%new(:)
+(SBNowPlayingBarMediaControlsView*)sharedControlInstance {
	return containerSingleton;
}
// selfHook
-(id)initWithFrame:(CGRect)frame {
	containerSingleton=self;
	return %orig;
}
%end


// new shit
%hook SBNowPlayingBar
-(void)viewWillAppear {
	NSLog(@"Drawing UI!");
	sharedSelf=self;
	%orig;
	Hook* hook=[Hook sharedHook];
	if(hook == nil) {
		UIButton* _orientationLockButton = hook(self, "_orientationLockButton");
		hook=[[Hook alloc] initWithButton:_orientationLockButton andView:MSHookIvar<id>(self, "_containerView") andIconLabel:MSHookIvar<SBIconLabel*>(self, "_orientationLabel")];
	}
	[hook hook];
}
-(void)prepareToAppear {
	if (kCFCoreFoundationVersionNumber < 550.52) { return %orig; }
	NSLog(@"Drawing UI on 4.2.1 hook!");
	sharedSelf=self;
	%orig;
	Hook* hook=[Hook sharedHook];
	if(hook == nil) {
		Class SBNowPlayingBarView = objc_getClass("SBNowPlayingBarView");		
		UIButton* _orientationLockButton = MSHookIvar<UIButton*>([SBNowPlayingBarView sharedControlInstance], "_orientationLockButton");
		[[Hook alloc] initWithButton:_orientationLockButton andView:(UIView*)[SBNowPlayingBarView sharedControlInstance] andIconLabel:MSHookIvar<SBIconLabel*>((UIView*)[SBNowPlayingBarView sharedControlInstance], "_orientationLabel")];
	}
	[hook hook];
}
%end