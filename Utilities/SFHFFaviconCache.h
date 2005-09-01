//
//  SHFFaviconCache.h
//  Delicious Client
//
//  Created by Buzz Andersen on 8/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SFHFFaviconCache : NSObject {
	NSMutableDictionary *memoryCache;
}

+ (SFHFFaviconCache *) sharedFaviconCache;
- (NSImage *) faviconForURL: (NSURL *) url forceRefresh: (BOOL) forceRefresh;

@end