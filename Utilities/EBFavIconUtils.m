//
//  EBFavIconUtils.m
//  Delicious Client
//
//  Created by Eric Blair on 6/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "EBFavIconUtils.h"
#import <WebKit/WebKit.h>
#import "NSFileManager+ESBExtensions.h"
#import "defines.h"

@interface EBFavIconUtils (Private)

+ (NSURL *)favIconURLForURL:(NSURL *)aURL;
+ (NSString *)createFileNameForURL: (NSURL *)aURL;

@end

@implementation EBFavIconUtils

+ (NSImage *) downloadFavIconForURL: (NSURL *) aURL
	forceDownload:(BOOL)aForceDownload {
	
	NSString * favIconFolder = [[NSFileManager defaultManager] getApplicationSupportSubpath: @"FavIcons"];
	NSString * favIconName = [EBFavIconUtils createFileNameForURL: aURL];
	
	if (favIconName == nil) {
		return nil;
	}
	
	NSString * favIconPath = [favIconFolder stringByAppendingPathComponent:favIconName];
	
	// If we're purging the cache or the file doesn't exist, pull it down from the web
	// Should set favIconPath to "" if the file doesn't exist on the server.
	BOOL iconExists = [[NSFileManager defaultManager] fileExistsAtPath:favIconPath];
	
	if (aForceDownload) {
		BOOL proceed = YES;

		// If the file exists, delete it - cache purge
		// If we can't delete, stop processing since we don't have write access to the required path.
		if(iconExists)
			proceed = [[NSFileManager defaultManager] removeFileAtPath:favIconPath handler:nil];
		
		if(proceed) {
			// This somehow needs to be augmented to look at the contents of any html
			// file located at the URL - we should give precendence to the LINK tags.
			NSURL * faviconURL = [EBFavIconUtils favIconURLForURL:aURL];
			NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:faviconURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
			[req setValue:kUSER_AGENT forHTTPHeaderField:@"User-Agent"];
			
			NSURLResponse * resp;
			NSError * error;

			NSData *returnData = [NSURLConnection sendSynchronousRequest: req returningResponse: &resp error: &error];
			
			if (returnData && !error) {
				NSImage *iconImage = [[NSImage alloc] initWithData: returnData];		
				NSImage *resizedImage = nil;

				if (iconImage) {
					resizedImage = [[NSImage alloc] initWithSize: kFAVICON_DISPLAY_SIZE];
					
					[resizedImage lockFocus];
					NSSize originalSize = [iconImage size];
					NSSize resizedSize = [resizedImage size];
					[iconImage drawInRect: NSMakeRect(0, 0, resizedSize.width, resizedSize.height) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
					[resizedImage unlockFocus];
					
					NSData *resizedData = [resizedImage TIFFRepresentation];
				
					if (resizedData) {
						[resizedData writeToFile: favIconPath atomically:YES];
					}
				}
				
				[iconImage release];
				return [resizedImage autorelease];
			}
			else
				NSLog(@"%@: %@", faviconURL, error);
		}
	}
	
	return [[[NSImage alloc] initWithContentsOfFile: favIconPath] autorelease];
}

@end

@implementation EBFavIconUtils (Private)

+ (NSString *)createFileNameForURL: (NSURL *)aURL {
	if ([aURL host] == nil) {
		return nil;
	}

	NSMutableString * hostName = [NSMutableString stringWithString: [aURL host]];

	// Convert '.' to '_'
	[hostName replaceOccurrencesOfString:@"."
		withString:@"_"
		options:nil
		range:NSMakeRange(0, [hostName length])];
	
	[hostName appendString:@".tiff"];
	
	return [[hostName copy] autorelease];
}

+ (NSURL *)favIconURLForURL:(NSURL *)aURL {
	NSURL * faviconURL = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@/favicon.ico", [aURL host]]];
	return [[faviconURL copy] autorelease];
}

@end
