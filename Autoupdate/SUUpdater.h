//
//  SUUpdater.h
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Before you use Sparkle in your app, you must set SUFeedURL in Info.plist to the
// address of the appcast on your webserver. If you don't already have an 
// appcast, please see the Sparkle documentation to learn about how to set one up.

// Please note that only .tar, .tbz, and .tgz archives are supported at this time.

// By default, Sparkle offers to show the user the release notes of the build they'll be
// getting, which it assumes are in the description (or body) field of the relevant RSS item.
// Set SUShowReleaseNotes to <false/> in Info.plist to hide the button.

extern NSString *SUCheckAtStartupKey;
extern NSString *SUFeedURLKey;
extern NSString *SUShowReleaseNotesKey;

@class RSS;
@interface SUUpdater : NSObject {
	NSURLDownload *downloader;
	NSString *downloadPath;
	
	NSPanel *statusWindow;
	NSTextField *statusField;
	NSTextField *downloadProgressField;
	NSProgressIndicator *progressBar;
	NSButton *actionButton;
}

// This method starts the update sequence. Pass YES if the action was user-initiated
// and NO if it was done automatically; the verbosity of the error reporting will reflect.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity;

// This IBAction is meant for a main menu item. Hook up any menu item to this action,
// and Sparkle will do the right thing.
- (IBAction)checkForUpdates:sender;

@end
