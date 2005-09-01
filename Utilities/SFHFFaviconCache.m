//
//  SHFFaviconCache.m
//  Delicious Client
//
//  Created by Buzz Andersen on 8/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SFHFFaviconCache.h"
#import "NSFileManager+ESBExtensions.h"
#import "defines.h"


@interface SFHFFaviconCache (Private)

- (NSImage *) downloadFaviconForURL: (NSURL *) aURL;
+ (NSString *) cachedFileNameForURL: (NSURL *) aURL;
+ (NSURL *) faviconURLForURL: (NSURL *) aURL;
- (NSMutableDictionary *) memoryCache;

@end

@implementation SFHFFaviconCache

static SFHFFaviconCache *sharedFaviconCache = nil;

+ (SFHFFaviconCache *) sharedFaviconCache {
	@synchronized (self) {
		if (!sharedFaviconCache) {
			sharedFaviconCache = [[SFHFFaviconCache alloc] init];
		}
	}

	return sharedFaviconCache;
}

- (id) init {
	if (self = [super init]) {
		memoryCache = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (NSImage *) faviconForURL: (NSURL *) url forceRefresh: (BOOL) forceRefresh {
	NSImage *favicon = nil;
	
	NSMutableDictionary *memCache = [self memoryCache];
	
	if (!forceRefresh) {
		favicon = [memCache objectForKey: [url absoluteString]];
		
		if (favicon) {
			return favicon;
		}
	}

	NSString * faviconFolder = [[NSFileManager defaultManager] getApplicationSupportSubpath: @"FavIcons"];
	NSString * faviconName = [SFHFFaviconCache cachedFileNameForURL: url];

	if (faviconName == nil) {
		return nil;
	}

	NSString * faviconPath = [faviconFolder stringByAppendingPathComponent:faviconName];	

	BOOL iconExists = [[NSFileManager defaultManager] fileExistsAtPath: faviconPath];
	
	if (!iconExists || forceRefresh) {
		/* download icon, write to disk */
		favicon = [self downloadFaviconForURL: url];
		
		if (favicon) {
			if (iconExists) {
				[[NSFileManager defaultManager] removeFileAtPath: faviconPath handler: nil];
			}
		
			NSImage *resizedImage = [[NSImage alloc] initWithSize: kFAVICON_DISPLAY_SIZE];
					
			[resizedImage lockFocus];
			NSSize originalSize = [favicon size];
			NSSize resizedSize = [resizedImage size];
			[favicon drawInRect: NSMakeRect(0, 0, resizedSize.width, resizedSize.height) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
			[resizedImage unlockFocus];
					
			NSData *resizedData = [resizedImage TIFFRepresentation];
				
			if (resizedData) {
				[resizedData writeToFile: faviconPath atomically:YES];
			}
			
			favicon = [resizedImage autorelease];
		}
	}
	else {
		/* load icon from disk */
		favicon = [[[NSImage alloc] initWithContentsOfFile: faviconPath] autorelease];
	}
	
	if (favicon) {
		[memCache setObject: favicon forKey: [url absoluteString]];
	}
	
	return favicon;
}

@end


@implementation SFHFFaviconCache (Private)

- (NSImage *) downloadFaviconForURL: (NSURL *) aURL {
	// This somehow needs to be augmented to look at the contents of any html
	// file located at the URL - we should give precendence to the LINK tags.
	NSURL * faviconURL = [SFHFFaviconCache faviconURLForURL: aURL];
	NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:faviconURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	[req setValue:kUSER_AGENT forHTTPHeaderField:@"User-Agent"];
			
	NSURLResponse * resp;
	NSError * error;

	NSData *returnData = [NSURLConnection sendSynchronousRequest: req returningResponse: &resp error: &error];
			
	if (returnData && !error) {
		return [[[NSImage alloc] initWithData: returnData] autorelease];		
	}

	return nil;
}

- (NSMutableDictionary *) memoryCache {
	return [[memoryCache retain] autorelease];
}

+ (NSString *) cachedFileNameForURL: (NSURL *) aURL {
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

+ (NSURL *) faviconURLForURL: (NSURL *) aURL {
	NSURL * faviconURL = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@/favicon.ico", [aURL host]]];
	return [[faviconURL copy] autorelease];
}

@end
