//
//  DCAPICache.h
//  Delicious Client
//
//  Created by Buzz Andersen on 10/22/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCAPIPost.h"
#import "DCAPIClient.h"
#import "NSFileManager+ESBExtensions.h"
#import "DCTypes.h"


@interface DCAPICache : NSObject {
	NSMutableDictionary *memoryCache;
	NSString *username;
	DCAPIClient *client;
}

+ (DCAPICache *) DCAPICacheForUsername: (NSString *) username client: (DCAPIClient *) client;
- initWithUsername: (NSString *) newUsername client: (DCAPIClient *) newClient;

- (void) setUsername: (NSString *) newUsername;
- (NSString *) username;
- (void) setClient: (DCAPIClient *) newClient;
- (DCAPIClient *) client;
- (void) setMemoryCache: (NSDictionary *) newMemoryCache;
- (NSMutableDictionary *) memoryCache;

- (void) refreshMemoryCacheWithPolicy: (DCAPICachePolicy) policy error: (NSError **) error;

- (void) addPosts: (NSArray *) posts clean: (BOOL) clean;
- (void) removePosts: (NSArray *) postURLs;

+ (NSDictionary *) readPostsFromDiskCache: (NSString *) cachePath;
+ (void) removePostsWithURLs: (NSArray *) urls fromDiskCache: (NSString *) cachePath;

+ (NSString *) diskCachePathForUsername: (NSString *) username;
+ (NSString *) lastRefreshFilePathForUsername: (NSString *) username;
+ (NSString *) userSupportFilesPathForUsername: (NSString *) username;


@end
