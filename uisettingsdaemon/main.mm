#import <Foundation/Foundation.h>
#import <Foundation/NSAutoReleasePool.h>
#include <unistd.h>
void dispatcher(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo) {
	char path[256]; //this SHOULD be enough
	const char* postNotify=[(NSString *)name UTF8String];
	NSLog(@"Got a notification! %s", postNotify);
	strcpy(path, "/Library/UISettings/Daemon/");
	strcat (path,postNotify);
	system(path);
}
int main(int argc, char **argv, char **envp) {
	NSLog(@"UISettingsDaemon: Ohai!");
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
	NSString* baseDir = @"/Library/UISettings/Daemon";
	NSDirectoryEnumerator* en = [fm enumeratorAtPath:baseDir];    
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	while (NSString* path = [en nextObject]) {
		NSLog(@"Registering: %@", path);
	        CFNotificationCenterAddObserver(r, NULL, &dispatcher, (CFStringRef)path, NULL, 0);	
	}
CFRunLoopRun();	
	[pool release];
	return 0;
}

// vim:ft=objc
