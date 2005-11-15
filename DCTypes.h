/*
 *  DCTypes.h
 *  Delicious Client
 *
 *  Created by Laurence Andersen on Thu Dec 23 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

typedef enum { DCBasicSearchType = 0, DCExtendedSearchType = 1, DCFullTextSearchType = 2 } DCSearchType;

typedef enum {
   DCAPICacheUseProtocolCachePolicy, // Ask del.icio.us if there is an update, reload from server based on that
   DCAPICacheReloadIgnoringCacheData, // Reload from del.icio.us whether or not we have a disk cache or server update
   DCAPICacheReturnCacheDataElseLoad, // Reload from del.icio.us if there is no local cache
   DCAPICacheReturnCacheDataDontLoad // Only use cache data (offline)
} DCAPICachePolicy;

typedef enum {
   CocoaliciousCacheUseProtocolCachePolicy, 
   CocoaliciousCacheReloadIgnoringCacheData, 
   CocoaliciousCacheReturnCacheDataElseLoad, 
   CocoaliciousCacheReturnCacheDataDontLoad, 
   CocoaliciousCacheUseMemoryCache
} CocoaliciousCachePolicy;

