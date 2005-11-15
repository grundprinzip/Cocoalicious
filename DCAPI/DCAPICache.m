//
//  DCAPICache.m
//  Delicious Client
//
//  Created by Buzz Andersen on 10/22/05.
//  Copyright 2005 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPICache.h"


@implementation DCAPICache

+ (DCAPICache *) DCAPICacheForUsername: (NSString *) username client: (DCAPIClient *) client {	
	DCAPICache *cache = [[DCAPICache alloc] initWithUsername: username client: client];
	return [cache autorelease];
}

- initWithUsername: (NSString *) newUsername client: (DCAPIClient *) newClient {
	if (self = [super init]) {
		[self setUsername: newUsername];
		[self setClient: newClient];
				
		return self;
	}
	
	return nil;
}

- (void) refreshMemoryCacheWithPolicy: (DCAPICachePolicy) policy error: (NSError **) error {
	NSString *theUsername = [self username];
	NSString *diskCachePath = [DCAPICache diskCachePathForUsername: theUsername];
	BOOL diskCacheExists = [[NSFileManager defaultManager] fileExistsAtPath: diskCachePath];
	NSString *lastRefreshFilePath = [DCAPICache lastRefreshFilePathForUsername: theUsername];
	BOOL lastRefreshFileExists = [[NSFileManager defaultManager] fileExistsAtPath: lastRefreshFilePath];

	BOOL serverHasUpdates = NO;

	if (client && lastRefreshFileExists && policy == DCAPICacheUseProtocolCachePolicy) {
		/* Must find out from del.icio.us whether there is an update */
		NSDate *serverUpdateTime = [[self client] requestLastUpdateTime: error];

		if (serverUpdateTime && !*error) {
			#warning stringWithContentsOfFile: is deprecated in 10.4
			NSString *lastRefreshTimeString = [NSString stringWithContentsOfFile: lastRefreshFilePath];
			NSCalendarDate *lastRefreshDate = [NSCalendarDate dateWithString: lastRefreshTimeString calendarFormat: kDEFAULT_DATE_TIME_FORMAT];

			if (lastRefreshDate && [lastRefreshDate compare: serverUpdateTime] == NSOrderedAscending) {
				serverHasUpdates = YES;
			}
		}
	}

	if (client && (!diskCacheExists && DCAPICacheReturnCacheDataElseLoad) || policy == DCAPICacheReloadIgnoringCacheData || serverHasUpdates) {
		/* Must reload from del.icio.us */
		NSArray *posts = [[self client] requestPostsFilteredByTag: nil count: nil];
		[self addPosts: posts];
		
		/* Note that we refreshed the posts now */
		[[NSFileManager defaultManager] createPathToFile: lastRefreshFilePath attributes: nil];
		NSString *lastRefreshTimeString = [[NSDate date] descriptionWithCalendarFormat: kDEFAULT_DATE_TIME_FORMAT timeZone: [NSTimeZone timeZoneWithName: kDEFAULT_TIME_ZONE_NAME] locale: nil];
		[lastRefreshTimeString writeToFile: lastRefreshFilePath atomically: YES];
	}
	else if (diskCacheExists) {
		/* Must reload from disk */
		NSDictionary *posts = [DCAPICache readPostsFromDiskCache: diskCachePath];
		[self setMemoryCache: posts];
	}
	else {
		[self setMemoryCache: [NSMutableDictionary dictionaryWithCapacity: 0]];
	}
} 

- (void) addPosts: (NSArray *) posts {	
	if (!memoryCache) {
		[self setMemoryCache: [NSMutableDictionary dictionaryWithCapacity: [posts count]]];
	}
		
	NSEnumerator *postEnumerator = [posts objectEnumerator];
	DCAPIPost *currentPost;
	
	while ((currentPost = (DCAPIPost *) [postEnumerator nextObject]) != nil) {
		[memoryCache setObject: currentPost forKey: [[currentPost URL] absoluteString]];
	}

	NSString *diskCachePath = [DCAPICache diskCachePathForUsername: [self username]];
	[DCAPICache addPosts: posts toDiskCache: diskCachePath];
}

- (void) removePostsWithURLs: (NSArray *) postURLs {
	if (!memoryCache) {
		return;
	}
	
	NSEnumerator *urlEnumerator = [postURLs objectEnumerator];
	NSURL *currentURL;
	
	while ((currentURL = [urlEnumerator nextObject]) != nil) {
		[[self memoryCache] removeObjectForKey: [currentURL absoluteString]];
	}

	NSString *diskCachePath = [DCAPICache diskCachePathForUsername: [self username]];
	[DCAPICache removePostsWithURLs: postURLs fromDiskCache: diskCachePath];
}

- (DCAPIPost *) postForURL: (NSURL *) url {
	if (!url) {
		return nil;
	}

	return [memoryCache objectForKey: [url absoluteString]];
}

- (void) setUsername: (NSString *) newUsername {
	if (username != newUsername) {
		[username release];
		username = [newUsername copy];
	}
}

- (NSString *) username {
	return [[username retain] autorelease];
}

- (void) setClient: (DCAPIClient *) newClient {
	if (client != newClient) {
		[client release];
		client = [newClient retain];
	}
}

- (DCAPIClient *) client {
	return [[client retain] autorelease];
}

- (void) setMemoryCache: (NSDictionary *) newMemoryCache {
	if (newMemoryCache != memoryCache) {
		[memoryCache release];
		memoryCache = [newMemoryCache mutableCopy];
	}
}

- (NSMutableDictionary *) memoryCache {
	return [[memoryCache retain] autorelease];
}

+ (NSString *) diskCachePathForUsername: (NSString *) username {
	return [[DCAPICache userSupportFilesPathForUsername: username] stringByAppendingPathComponent: kPOST_CACHE_FILE_NAME];
}

+ (NSString *) lastRefreshFilePathForUsername: (NSString *) username {
	return [[DCAPICache userSupportFilesPathForUsername: username] stringByAppendingPathComponent: kLAST_REFRESH_FILE_NAME];
}

+ (NSString *) userSupportFilesPathForUsername: (NSString *) username {
	return [[[NSFileManager defaultManager] getApplicationSupportFolder] stringByAppendingPathComponent: username];
}

+ (NSDictionary *) readPostsFromDiskCache: (NSString *) cachePath {
	NSDictionary *cache = [NSDictionary dictionaryWithContentsOfFile: cachePath];
	
	if (!cache) {
		return nil;
	}

	NSEnumerator *keys = [[cache allKeys] objectEnumerator];
	NSString *currentPostURLString;
	NSMutableDictionary *postList = [NSMutableDictionary dictionaryWithCapacity: 1];
	
	while ((currentPostURLString = (NSString *) [keys nextObject]) != nil) {
		NSDictionary *currentPostDictionary = [cache objectForKey: currentPostURLString];
		DCAPIPost *currentPost = [DCAPIPost postWithDictionary: currentPostDictionary URL: [NSURL URLWithString: currentPostURLString]];
		
		if (currentPost) {
			[postList setObject: currentPost forKey: currentPostURLString];
		}
	}
	
	return postList;
}

+ (void) addPosts: (NSArray *) posts toDiskCache: (NSString *) cachePath {
	NSMutableDictionary *cache;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: cachePath]) {
		cache = [NSMutableDictionary dictionaryWithContentsOfFile: cachePath];
	}
	
	if (!cache) {
		cache = [NSMutableDictionary dictionaryWithCapacity: [posts count]];
	}
	
	NSEnumerator *postEnumerator = [posts objectEnumerator];
	DCAPIPost *currentPost;
	
	while ((currentPost = (DCAPIPost *) [postEnumerator nextObject]) != nil) {
		NSDictionary *postDictionary = [currentPost dictionaryRepresentation];
		[cache setObject: postDictionary forKey: [[currentPost URL] absoluteString]];
	}
	
	[[NSFileManager defaultManager] createPathToFile: cachePath attributes: nil];
	
	if (![cache writeToFile: cachePath atomically: YES]) {
		NSLog(@"Can't write cache!");
	}
}

+ (void) removePostsWithURLs: (NSArray *) urls fromDiskCache: (NSString *) cachePath {
	if (![[NSFileManager defaultManager] fileExistsAtPath: cachePath]) {
		return;
	}

	NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile: cachePath];

	NSEnumerator *urlEnumerator = [urls objectEnumerator];
	NSURL *currentURL;
	
	while ((currentURL = [urlEnumerator nextObject]) != nil) {
		[cache removeObjectForKey: [currentURL absoluteString]];
	}
	
	if (![cache writeToFile: cachePath atomically: YES]) {
		NSLog(@"Can't write cache!");
	}
}

- (void) dealloc {
	[username release];
	[memoryCache release];
	[client release];
	[super dealloc];
}

@end
