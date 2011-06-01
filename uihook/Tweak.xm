/*
 *
 * Welcome to the wonderful world of UIHook!
 * (aka Phoneix, Arizona)
 * This is a module of UISettings.
 * It links SpringBoard to the UISettings Dylib and it provides various hooks
 * It's really hacky. If you wanna do something in ur spare time, rewrite a cleaner version of this.
 * The API for UICore is really simple.
 * The Hook class is useful, it manages everything.
 * To port to newer firmwares, look up the Hook class and the 4.2.1 / 4.3 / 4.1 module (already included)
 *
 * FIX TEMPLATE:
 * 
 * ===============================
 * FIX FOR THE <description> ISSUE
 * made by <name> / dd.mm.yyyy
 * [optional] thanks to <name2>
 * Comment
 * ==============================
 *
 * This standard makes code easy  to read.
 * Also, for the love of god, use indentation.
 *
 * ~qwertyoruiop(2011)
 * 
 */
#define hook(x, y) MSHookIvar<id>(x, y);
#import <dlfcn.h>
#import <SpringBoard/SpringBoard.h>
#include "substrate.h"
#import <notify.h>
#define kHookVer "0.3"

/*
 * ===============================
 * FIX FOR TEH ROTATIONIMAGE+SIZE ISSUE
 * SIZE issue not yet fixed
 * made by qwertyoruiop / 31.05.2011
 * A bit hacky.
 * ===============================
 */
static id image_=nil;
%hook UIImage
+(id)imageNamed:(id)name
{
	if([name isEqualToString:@"RotationLockButton"]||[name isEqualToString:@"RotationUnlockButton"]){
		if(!image_){
			/*
			 * TODO:
			 * Add themeing support.
			 * And, if possible, fix teh WebThread crash.
			 */
			id imageData = [NSData dataWithContentsOfFile:@"/Library/UISettings/Icons/uisettings.png"];
			id image_f_ = [UIImage imageWithData:imageData];
			/*
			CGSize toSize=[objc_getClass("SBIcon") defaultIconImageSize];
			UIGraphicsBeginImageContext(toSize);
			[image_f_ drawInRect:CGRectMake(0,0,toSize.width,toSize.height)];
			image_=UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			[image_f_ release];
			[imageData release];
			*/
			image_=image_f_;
		}
		return image_;
	}
	return %orig;
}
%end

// Hooks for the SpringBoard class

static id __sb=nil;
%hook SpringBoard
- (id)init
{
	__sb=self;
	return %orig;
}
%new(@@:)
+ (id)sharedBoard
{
	return __sb;
}
%end

// Hooks for the SBAppSwitcherBarView class

static id msg=nil;
%hook SBAppSwitcherBarView
+(id)alloc
{
	msg=%orig;
	return msg;
}
%new(v@:)
+(id)mesg
{
	return msg;
}
%end

// Hooks for the SBNowPlayingBar class

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
%new(v@:)
- (void)_orientationLockHit:(id)unused
{
	[self _toggleButtonHit:nil];
}
%end

// UICore manager

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

// UICore <====> UIHook helper

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

// Old hooks, from UISettingsDraft1
// There are loads of errors (e.g. new's format). I know.
// I just CBA to fix them

%ctor {
	NSLog(@"UISettingsDraft2 - based on nothing");
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


// Hooks for various firmwares

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
		UIButton* _orientationLockButton;
		id label__;
		if([[SBNowPlayingBarView sharedControlInstance] respondsToSelector:@selector(toggleButton)]){
			_orientationLockButton=[[SBNowPlayingBarView sharedControlInstance] performSelector:@selector(toggleButton) withObject:nil];
			label__=MSHookIvar<SBIconLabel*>((UIView*)containerSingleton, "_trackLabel");
		} else {
			 _orientationLockButton = MSHookIvar<UIButton*>([SBNowPlayingBarView sharedControlInstance], "_orientationLockButton");
			label__=MSHookIvar<SBIconLabel*>((UIView*)containerSingleton, "_orientationLabel");
		}
		hook=[[Hook alloc] initWithButton:_orientationLockButton andView:(UIView*)[SBNowPlayingBarView sharedControlInstance] andIconLabel:label__];
	}
	[hook hook];
}
%end

%hook SBAppSwitcherController
- (void)viewWillAppear
{
	notify_post("com.qwerty.uisettings.reload");	
	%orig;
}
%end
