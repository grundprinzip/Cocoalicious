//
//  SUUpdater.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUpdater.h"
#import "RSS.h"
#import <stdio.h>

NSString *SUCheckAtStartupKey = @"SUCheckAtStartup";
NSString *SUFeedURLKey = @"SUFeedURL";
NSString *SUShowReleaseNotesKey = @"SUShowReleaseNotes";

NSString *SUHostAppName()
{
	return [[NSFileManager defaultManager] displayNameAtPath:[[NSBundle mainBundle] bundlePath]];
}

@implementation SUUpdater

- (BOOL)promptUserForStartupPreference
{
	// The SHOULD_CHECK_FOR_UPDATES_ON_STARTUP_BODY should have a %@ where the application name will be inserted.
	// If you don't want that, just delete it and then delete the last argument to this NSRunAlertPanel call.
	NSString *appName = SUHostAppName();
	return (NSRunAlertPanel(NSLocalizedStringFromTable(@"SHOULD_CHECK_FOR_UPDATES_ON_STARTUP_TITLE", @"Sparkle", @"Should the app check for updates on startup? (dialog title)"), 
							NSLocalizedStringFromTable(@"SHOULD_CHECK_FOR_UPDATES_ON_STARTUP_BODY", @"Sparkle", @"Should the app check for updates on startup? (dialog body)"),
							NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil, appName)) == NSAlertDefaultReturn ? YES : NO;
	// ^ most convoluted return line evar
}

- (void)awakeFromNib
{
#warning TODO: Only check on startup once every n days (to ease server loads).
	NSNumber *shouldCheckAtStartup = [[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey];
	if (!shouldCheckAtStartup) // hasn't been set yet; ask the user
	{
		shouldCheckAtStartup = [NSNumber numberWithBool:[self promptUserForStartupPreference]];
		[[NSUserDefaults standardUserDefaults] setObject:shouldCheckAtStartup forKey:SUCheckAtStartupKey];
	}
	
	if ([shouldCheckAtStartup boolValue])
		[self checkForUpdatesAndNotify:NO];
}

- (void)dealloc
{
	[downloadPath release];
	[super dealloc];
}

// If the notify flag is YES, Sparkle will say when it can't reach the server and when there's no new update.
// This is generally useful for a menu item--when the check is explicitly invoked.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity
{
	// This method name is a little misleading; we're going to split the actual task at hand off into another thread to avoid blocking.
	[NSThread detachNewThreadSelector:@selector(fetchFeedAndNotify:) toTarget:self withObject:[NSNumber numberWithBool:verbosity]];
}

- (IBAction)checkForUpdates:sender
{
	// If we're coming from IB, then we want to be more verbose.
	[self checkForUpdatesAndNotify:YES];
}

- (NSString *)newestRemoteVersionStringInFeed:(RSS *)feed
{
	NSDictionary *enclosure = [[feed newestItem] objectForKey:@"enclosure"];
	
	// Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
	// 1. A "version" attribute on the enclosure tag, which I made up just for this purpose. It's not part of the RSS2 spec.
	// 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
	//    that it will look like this: http://something.com/YourApp_0.5.zip It'll read whatever's between the last
	//    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
	//    The big caveat with this is that you can't have underscores in your version strings, as that'll confused Sparkle.
	//    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
	NSString *newVersion = [enclosure objectForKey:@"version"];
	if (!newVersion) // no version attribute
	{
		// Separate the url by underscores and take the last component, as that'll be closest to the end.
		NSString *versionAndExtension = [[[enclosure objectForKey:@"url"] componentsSeparatedByString:@"_"] lastObject];
		// Now we remove the extension. Hopefully, this will be the version.
		newVersion = [versionAndExtension stringByDeletingPathExtension];
	}
	if (!newVersion) // don't really know what to do!
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"BAD_VERSION_STRING", @"Sparkle", @"Can't get a version string from teh feed!"), NSLocalizedString(@"OK", nil), nil, nil);
		//[NSException raise:@"RSSParseFailed" format:@"Couldn't read a version string from the appcast feed at %@", SUFeedURL];
	}
	
	return newVersion;
}

- (NSString *)currentVersionString
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (void)fetchFeedAndNotify:(NSNumber *)verbosity
{
#warning TODO: Handle caching / HTTP headers to see if the request is really necessary.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	RSS *feed;
	BOOL shouldContinue = YES;
	NS_DURING
		NSString *path = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUFeedURLKey];
		if (!path) { [NSException raise:@"SUNoFeedURL" format:@"No feed URL is specified in the Info.plist!"]; }
		feed = [[RSS alloc] initWithURL:[NSURL URLWithString:path] normalize:YES];
	NS_HANDLER
		shouldContinue = NO;
		if ([[localException name] isEqualToString:@"RSSDownloadFailed"] || [[localException name] isEqualToString:@"RSSNoData"])
		{
			// We only run a panel on these if the notify flag is YES. 
			if (![verbosity boolValue])
				NS_VOIDRETURN;
		}
		// We have to make the main thread do this instead of doing it ourselves because secondary
		// threads can't do GUI stuff (like popping alert dialogs).
		[self performSelectorOnMainThread:@selector(feedFetchDidFailWithException:) withObject:localException waitUntilDone:NO];
	NS_ENDHANDLER
	
	if (shouldContinue)
		[self performSelectorOnMainThread:@selector(didFetchFeedWithInfo:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:feed, @"feed", verbosity, @"notify", nil] waitUntilDone:NO];
	[pool release];
}

- (void)feedFetchDidFailWithException:(NSException *)exception
{
	NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"RSS_ERROR", @"Sparkle", @"An error occurred while fetching / parsing the feed!"), NSLocalizedString(@"OK", nil), nil, nil, [exception reason]);
}

- (void)setStatusText:(NSString *)statusText
{
	[statusField setAttributedStringValue:[[[NSAttributedString alloc] initWithString:statusText attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]] forKey:NSFontAttributeName]] autorelease]];
}

- (void)setActionButtonTitle:(NSString *)title
{
	[actionButton setTitle:title];
	[actionButton sizeToFit];
	// Except we're going to add 15 px for padding.
	[actionButton setFrameSize:NSMakeSize([actionButton frame].size.width + 15, [actionButton frame].size.height)];
	// Now we have to move it over so that it's always 15px from the side of the window.
	[actionButton setFrameOrigin:NSMakePoint([[statusWindow contentView] bounds].size.width - 15 - [actionButton frame].size.width, [actionButton frame].origin.y)];
}

- (void)createStatusWindow
{
	// Yeah, it's really hacky that we're programmatically making this window,
	// but this project is made so that you can just drop it in any project, and
	// adding .nibs would complicate things. You'd better appreciate it.
	
	// Numeric literals abound! Run for the hills! But they're mostly taken from the HIG dialog reference layout.
	
	statusWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 384, 106) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[statusWindow center];
	[statusWindow setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"STATUS_WINDOW_TITLE", @"Sparkle", "Title for the update status window"), SUHostAppName()]];
	
	id contentView = [statusWindow contentView];
	NSSize windowSize = [contentView bounds].size;
	
	// Place the app icon.
	NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(24, windowSize.height - 15 - 64, 64, 64)] autorelease];
	[appIconView setImageFrameStyle:NSImageFrameNone];
	[appIconView setImage:[NSApp applicationIconImage]];
	[contentView addSubview:appIconView];
	
	// Place the status field.
	statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, windowSize.height - 15 - 17, 260, 17)] autorelease];
	[self setStatusText:NSLocalizedStringFromTable(@"DOWNLOADING_UPDATE", @"Sparkle", @"Downloading update status text")];
	[statusField setBezeled:NO];
	[statusField setEditable:NO];
	[statusField setDrawsBackground:NO];
	[contentView addSubview:statusField];
	
	// Place the download completion field.
	downloadProgressField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, 22, 150, 17)] autorelease];
	[downloadProgressField setBezeled:NO];
	[downloadProgressField setEditable:NO];
	[downloadProgressField setDrawsBackground:NO];
	[contentView addSubview:downloadProgressField];
	
	// Place the progress bar.
	progressBar = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24 + 64 + 16, windowSize.height - 15 - 17 - 8 - 20, 260, 20)] autorelease];
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[progressBar setControlSize:NSRegularControlSize];
	[contentView addSubview:progressBar];
	
	// Place the action button.
	actionButton = [[[NSButton alloc] initWithFrame:NSMakeRect(windowSize.width - 15 - 82, 12, 82, 32)] autorelease];
	[actionButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[actionButton setBezelStyle:NSRoundedBezelStyle];
	[self setActionButtonTitle:NSLocalizedString(@"Cancel", nil)];
	[actionButton setTarget:self];
	[actionButton setAction:@selector(cancelDownload:)];
	[contentView addSubview:actionButton];
}

- (void)showReleaseNotesOfFeed:(RSS *)feed
{
	NSPanel *notesPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 478, 283) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[notesPanel setTitle:NSLocalizedStringFromTable(@"RELEASE_NOTES", @"Sparkle", "Release Notes")];
	
	id contentView = [notesPanel contentView];
	NSSize windowSize = [contentView bounds].size;
	
	// Place the application icon
	NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(20, windowSize.height - 15 - 64, 64, 64)] autorelease];
	[appIconView setImageFrameStyle:NSImageFrameNone];
	[appIconView setImage:[NSApp applicationIconImage]];
	[contentView addSubview:appIconView];
	
	// Place the release notes title text
	NSTextField *notesTitle = [[[NSTextField alloc] initWithFrame:NSMakeRect(20 + 64 + 15, windowSize.height - 15 - 17, 360, 17)] autorelease];
	[notesTitle setAttributedStringValue:[[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"RELEASE_NOTES", @"Sparkle", "Release Notes") attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]] forKey:NSFontAttributeName]] autorelease]]; // A very long line to make the words "Release Notes" bold.
	[notesTitle setBezeled:NO];
	[notesTitle setEditable:NO];
	[notesTitle setDrawsBackground:NO];
	[contentView addSubview:notesTitle];
	
	// Place the release notes reader
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(20 + 64 + 16, 54, 358, 184)] autorelease];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setBorderType:NSBezelBorder];
	[contentView addSubview:scrollView];
	
	NSTextView *textView = [[NSTextView alloc] initWithFrame:[[scrollView contentView] bounds]];
	NSAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithHTML:[NSData dataWithBytes:[[[feed newestItem] objectForKey:@"description"] cString] length:[(NSString *)[[feed newestItem] objectForKey:@"description"] length]] options:nil documentAttributes:nil] autorelease];
	[[textView textStorage] setAttributedString:attributedString];
	[textView setEditable:NO];
	[textView setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	[scrollView setDocumentView:textView];
	
	// Place the OK button.
	NSButton *okButton = [[[NSButton alloc] initWithFrame:NSMakeRect(windowSize.width - 14 - 82, 12, 82, 32)] autorelease];
	[okButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[okButton setTitle:NSLocalizedString(@"OK", nil)];
	[okButton setKeyEquivalent:@"\r"];
	[okButton setBezelStyle:NSRoundedBezelStyle];
	[okButton setTarget:self];
	[okButton setAction:@selector(stopReleaseNotes:)];
	[contentView addSubview:okButton];
	
	[NSApp runModalForWindow:notesPanel];
}

- (IBAction)stopReleaseNotes:sender
{
	[NSApp stopModal];
	[[sender window] orderOut:self];
	[[sender window] release];
}

- (BOOL)shouldPerformUpdateWithFeed:(RSS *)feed
{
	// This method is called when there's an update to determine if the user wants it.
	NSString *appName = SUHostAppName();
	id title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"A_NEW_VERSION_IS_AVAILABLE_TITLE", @"Sparkle", @"There's a new version. Want it? (dialog title)"), appName];
	
	id body = [NSString stringWithFormat:NSLocalizedStringFromTable(@"A_NEW_VERSION_IS_AVAILABLE_BODY", @"Sparkle", @"There's a new version. Want it? (dialog body)"), appName, [self newestRemoteVersionStringInFeed:feed], [self currentVersionString]];
	
	id downloadUpdate = NSLocalizedStringFromTable(@"DOWNLOAD_UPDATE", @"Sparkle", @"Download Update");
	id notNow = NSLocalizedStringFromTable(@"NOT_NOW", @"Sparkle", @"Not Now");
	id viewReleaseNotes = NSLocalizedStringFromTable(@"VIEW_RELEASE_NOTES", @"Sparkle", "View Release Notes");
	
	int result;
	do
	{
		// Get the release notes option from Info.plist.
		NSNumber *showNotesObj = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUShowReleaseNotesKey];
		BOOL showNotes;
		if (!showNotesObj)
			showNotes = YES;
		else
			showNotes = [showNotesObj boolValue];
		
		result = NSRunAlertPanel(title, body, downloadUpdate, notNow, showNotes ? viewReleaseNotes : nil);
		if (result == NSAlertOtherReturn)
		{
			[self showReleaseNotesOfFeed:feed];
		}
	}
	while (result == NSAlertOtherReturn);
	return result;
}

- (void)didFetchFeedWithInfo:(NSDictionary *)info
{
	RSS *feed = [info objectForKey:@"feed"];
	BOOL notify = [[info objectForKey:@"notify"] boolValue];
	
	NSString *newestVersionString = [self newestRemoteVersionStringInFeed:feed];
	if (!newestVersionString) { return; }
	if ([[self currentVersionString] isEqualToString:newestVersionString])
	{
		// We only notify on no new version when the notify flag is on.
		if (notify)
		{
			NSRunAlertPanel(NSLocalizedStringFromTable(@"NO_UPDATE_TITLE", @"Sparkle", @"No update is available (title)"), NSLocalizedStringFromTable(@"NO_UPDATE_TEXT", @"Sparkle", @"No update is available (text)"), NSLocalizedString(@"OK", nil), nil, nil, SUHostAppName(), [self currentVersionString]);
		}
	}
	else
	{
		// There's a new version!
		if (![self shouldPerformUpdateWithFeed:feed]) { return; }
		[self createStatusWindow];
		[statusWindow makeKeyAndOrderFront:self];
		NSString *urlString = [[[feed newestItem] objectForKey:@"enclosure"] objectForKey:@"url"];
		downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] delegate:self];
	}
	[feed release];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[progressBar setIndeterminate:NO];
	[progressBar startAnimation:self];
	[progressBar setMaxValue:[response expectedContentLength]];
	[progressBar setDoubleValue:0];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
{
	// If name ends in .txt, the server probably has a stupid MIME configuration. We'll give
	// the developer the benefit of the doubt and chop that off.
	if ([[name pathExtension] isEqualToString:@"txt"])
		name = [name stringByDeletingPathExtension];
	
	// We create a temporary directory in /tmp and stick the file there.
	NSString *tempDir = [NSString stringWithCString:tmpnam(NULL) encoding:[NSString defaultCStringEncoding]];
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:tempDir attributes:nil];
	if (!success)
	{
		[NSException raise:@"SUFailTmpWrite" format:@"Couldn't create temporary directory in /tmp"];
		[download cancel];
		[download release];
	}
	downloadPath = [[tempDir stringByAppendingPathComponent:name] retain];
	[download setDestination:downloadPath allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	[progressBar setDoubleValue:[progressBar doubleValue] + length];
	[downloadProgressField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"UPDATE_COMPLETION_TEXT", @"Sparkle", @"Download progress status text"), [progressBar doubleValue] / 1024.0, [progressBar maxValue] / 1024.0]];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[download release];
	
	// Now we have to extract the downloaded archive.
	[self setStatusText:NSLocalizedStringFromTable(@"EXTRACTING_UPDATE", @"Sparkle", @"Extraction status text")];
	NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"tar -jxC \"$DESTINATION\"", @"tbz", @"tar -zxC \"$DESTINATION\"", @"tgz", @"tar -xC \"$DESTINATION\"", @"tar", nil];
	NSString *command = [commandDictionary objectForKey:[downloadPath pathExtension]];
	if (!command)
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"BAD_ARCHIVE_TYPE", @"Sparkle", @"Can't extract this kind of archive!"), NSLocalizedString(@"OK", nil), nil, nil, [downloadPath pathExtension], [commandDictionary allKeys]);
		[statusWindow orderOut:self];
		[statusWindow release];
		return;
		//[NSException raise:@"SUCannotHandleFile" format:@"Can't extract %@ files; I can only handle %@", [downloadPath pathExtension], [commandDictionary allKeys]];
	}
	
	// Get the file size.
	NSNumber *fs = [[[NSFileManager defaultManager] fileAttributesAtPath:downloadPath traverseLink:NO] objectForKey:NSFileSize];
	if (!fs)
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"CANT_FIND_DOWNLOADED_FILE", @"Sparkle", @"Can't find the downloaded file!"), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		return;
		//[NSException raise:@"SUCannotReadFile" format:@"Can't determine downloaded file size"];
	}
	long fileSize = [fs longValue];
	
	// Thank you, Allan Odgaard!
	// (who wrote the following extraction alg.)
	[progressBar setIndeterminate:NO];
	[progressBar setDoubleValue:0.0];
	[progressBar setMaxValue:fileSize];
	[progressBar startAnimation:self];
	
	long current = 0;
	FILE *fp, *cmdFP;
	if (fp = fopen([downloadPath UTF8String], "r"))
	{
		setenv("DESTINATION", [[downloadPath stringByDeletingLastPathComponent] UTF8String], 1);
		if (cmdFP = popen([command cString], "w"))
		{
			char buf[32*1024];
			long len;
			while(len = fread(buf, 1, 32 * 1024, fp))
			{
				current += len;
				[progressBar setDoubleValue:(double)current];
				[downloadProgressField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"UPDATE_COMPLETION_TEXT", @"Sparkle", @"Download progress status text"), current / 1024.0, fileSize / 1024.0]];
				
				NSEvent *event;
				while(event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])
					[NSApp sendEvent:event];
				
				fwrite(buf, 1, len, cmdFP);
			}
			pclose(cmdFP);
		}
		fclose(fp);
	}
	
	[self setStatusText:NSLocalizedStringFromTable(@"READY_TO_INSTALL", @"Sparkle", @"Status text after extraction.")];
	[self setActionButtonTitle:NSLocalizedStringFromTable(@"INSTALL_AND_RESTART", @"Sparkle", @"Button text for installing and restarting.")];
	[downloadProgressField setHidden:YES];
	[actionButton setAction:@selector(installAndRestart:)];
	[NSApp requestUserAttention:NSInformationalRequest];
	[actionButton setKeyEquivalent:@"\r"]; // Make the button active
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[statusWindow orderOut:self];
	[statusWindow release];
	NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"DOWNLOAD_ERROR", @"Sparkle", @"Download error"), NSLocalizedString(@"OK", nil), nil, nil, [error localizedDescription]);
}

- (IBAction)installAndRestart:sender
{
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[self setStatusText:NSLocalizedStringFromTable(@"INSTALLING_UPDATE", @"Sparkle", @"Installing status text.")];
	[progressBar display];
	[statusField display];
	
	// We expect that the archive we downloaded contains a file with the same name as the executable we're running.
	NSString *currentPath = [[NSBundle mainBundle] bundlePath];
	NSString *executableName = [currentPath lastPathComponent];
	NSString *targetPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableName];
	if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"CANT_FIND_NEW_APP", @"Sparkle", @"Can't find the new app!"), NSLocalizedString(@"OK", nil), nil, nil, targetPath);
		[statusWindow orderOut:self];
		[statusWindow release];
		return;
		//[NSException raise:@"SUFileNotFound" format:@"Couldn't find a new version of the app where I expected it to be (%@). The .app in the archive should have the same filename as the current executable.", targetPath];
	}
	
	// Now we delete the old one.
	int tag = 0;
	if (![[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[currentPath stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:executableName] tag:&tag])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"CANT_DELETE_CURRENT_APP", @"Sparkle", @"Can't delete the old app!"), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		return;
		//[NSException raise:@"SUCouldntDeleteCurrentApp" format:@"Couldn't delete the current copy of the application. Is it read-only or something?"];
	}
	
	// And the new one is born.
	if (![[NSFileManager defaultManager] movePath:targetPath toPath:currentPath handler:NULL])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"UPDATE_ERROR", @"Sparkle", @"Update error title text"), NSLocalizedStringFromTable(@"CANT_INSTALL_NEW_APP", @"Sparkle", @"Can't delete the old app!"), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		return;
	}
	
	[[NSWorkspace sharedWorkspace] openFile:currentPath];
	[NSApp terminate:self];
}

- (IBAction)cancelDownload:sender
{
	[downloader cancel];
	[downloader release];
	[statusWindow orderOut:self];
	[statusWindow release];
}

@end
