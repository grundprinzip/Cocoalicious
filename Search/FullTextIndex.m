//
//  FullTextIndex.m
//  Delicious Client
//
//  Created by Andrew Wooster on Sat Oct 16 2004.
//  Copyright (c) 2004 Andrew Wooster. All rights reserved.
//

#import "FullTextIndex.h"

static double kREQUEST_TIMEOUT_INTERVAL = 30.0;
static NSString *kUSER_AGENT_HTTP_HEADER = @"User-Agent";

@implementation FullTextIndex

- (id) init
{
	if (self = [super init]) {
        textIndex = nil;
        searching = NO;
        indexing = NO;
        indexLock = [[NSLock alloc] init];
        results = [[NSMutableArray alloc] init];
        resultsLock = [[NSLock alloc] init];
        searchLock = [[NSLock alloc] init];
        currentSearchID = 0;
	}
	return self;
}

- (void) dealloc
{
    [indexLock release];
    [results release];
    [resultsLock release];
    [searchLock release];
    [self closeIndex];
}

- (SKIndexRef)textIndex
{
    [self flushIndex];
    return textIndex;
}

#pragma mark Index File Handling
- (void)openIndex
{
    // Check if index is already open.
    if (textIndex) {
        return;
    }
    
    NSString *indexPath = [self indexPath];
    NSURL *indexFileUrl = [NSURL fileURLWithPath: indexPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Index file already exists.
    if ([fm fileExistsAtPath: indexPath]) {
        [indexLock lock];
        textIndex = SKIndexOpenWithURL((CFURLRef)indexFileUrl,
                                       (CFStringRef)kTEXT_INDEX_VERSION,
                                       true);
        [indexLock unlock];
    }
    
    // Load existing index, if not already loaded.
    if (!textIndex) {
        [indexLock lock];
        textIndex = SKIndexCreateWithURL((CFURLRef)indexFileUrl,
                                         // Actually index name.
                                         (CFStringRef)kTEXT_INDEX_VERSION,
                                         // Terms to documents.
                                         kSKIndexInverted,
                                         // No need to set these options.
                                         NULL);
        [indexLock unlock];
    }
    
    //!! Doesn't do anything unless we use SKIndexAddDocument.
    //SKLoadDefaultExtractorPlugIns();
    NSAssert(textIndex, @"textIndex not loaded.");
}

- (void)closeIndex
{
    [indexLock lock];
    if (textIndex) {
        CFRelease(textIndex);
    }
    textIndex = nil;
    [indexLock unlock];
}

- (void)flushIndex
{
    [indexLock lock];
    if (textIndex) {
        SKIndexFlush(textIndex);
    }
    [indexLock unlock];
}

- (NSString *)indexPath
{
    return [[kTEXT_INDEX_PATH stringByAppendingPathComponent: kTEXT_INDEX_NAME]
        stringByExpandingTildeInPath];
}

- (NSMutableArray *)results
{
    // Since this can change at any time, return a copy.
    return [[results copy] autorelease];
}

- (BOOL)searching
{
    return searching;
}

- (BOOL)indexing
{
    return indexing;
}

#pragma mark Index Utilities
- (void)logIndexInformation
{
    [indexLock lock];
    if (textIndex != nil) {
        CFIndex numberOfDocuments = SKIndexGetDocumentCount(textIndex);
        NSLog(@"%d documents in index.", numberOfDocuments);
        CFIndex numberOfTerms = SKIndexGetMaximumTermID(textIndex);
        NSLog(@"%d terms in index.", numberOfTerms);
    } else {
        NSLog(@"No index loaded.");
    }
    [indexLock unlock];
}

#pragma mark Index Indexing
- (void)addDocumentToIndex:(NSURL *)url
               withContent:(NSString *)content
{
    if (AWOOSTER_DEBUG) {
        NSLog(@"Adding %@", url);
        NSLog(@"With contents:");
        NSLog(@"%@", content);
    }
    [self openIndex]; //!! is this necessary?
    if (textIndex == nil) {
        NSLog(@"textIndex is nil, not processing: %@", [url absoluteString]);
        return;
    }
    [indexLock lock];
    indexing = YES;
    // CFURL's, funnily enough, don't preserve the entire URL.
    // Great.
    // So, instead, create an SKDocument with the name being the URL.
    SKDocumentRef document = SKDocumentCreate((CFStringRef)@"file",
                                              NULL,
                                              (CFStringRef)[url description]);
    if (!SKIndexAddDocumentWithText(textIndex,
                                    document,
                                    (CFStringRef)content,
                                    true)) {
        NSLog(@"There was a problem adding %@", [url absoluteString]);
    }
    CFRelease(document);
    
    indexing = NO;
    [indexLock unlock];
    [self flushIndex]; //!! May want to move for efficiency.
}

- (void) search:(NSDictionary *)searchDict
{
    // Wait for the current search to end.
    [searchLock lock]; [searchLock unlock];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id anObject = [searchDict objectForKey:@"anObject"];
    SEL aSelector = 
        NSSelectorFromString([searchDict objectForKey:@"aSelector"]);
    NSString *query = [searchDict objectForKey:@"query"];

    if (!textIndex) {
        [self openIndex];
    }
    
    if (AWOOSTER_DEBUG) {
        NSLog(@"Searching for %@", query);
        [self logIndexInformation];
    }
    if (!textIndex) {
        NSLog(@"textIndex is nil, not processing search for: %@",
              query);
        [pool release];
        return;
    }
    
    [searchLock lock];
    [results removeAllObjects];
    searching = YES;
    // We need a search group.
    SKIndexRef indexArray[1];
    indexArray[0] = textIndex;
    CFArrayRef searchArray = CFArrayCreate(NULL,
                                           (void *)indexArray,
                                           1,
                                           &kCFTypeArrayCallBacks);
    SKSearchGroupRef searchGroup = SKSearchGroupCreate(searchArray);
    SKSearchResultsRef searchResults
        = SKSearchResultsCreateWithQuery(searchGroup,
                                         (CFStringRef)query,
                                         kSKSearchRequiredRanked,
                                         kTEXT_SEARCH_MAX_RESULTS,
                                         NULL,
                                         NULL);
    SKDocumentRef outDocumentsArray[kTEXT_SEARCH_CHUNK_SIZE];
    int resultCount = 0;
    int location;
    resultCount = SKSearchResultsGetCount(searchResults);
    if (AWOOSTER_DEBUG) {
        NSLog(@"%d results", resultCount);
    }
    for (location = 0; 
         location < resultCount; 
         location += kTEXT_SEARCH_CHUNK_SIZE) {
        int count = 
            SKSearchResultsGetInfoInRange(searchResults,
                                          CFRangeMake(location,
                                                      kTEXT_SEARCH_CHUNK_SIZE),
                                          outDocumentsArray,
                                          NULL,
                                          NULL);
        int i;
        for (i = 0; i < count; i++) {
            NSString *url = (NSString *)SKDocumentGetName(outDocumentsArray[i]);
            if (AWOOSTER_DEBUG) {
                NSLog(@"  %@", [NSURL URLWithString: url]);
            }
            [resultsLock lock];
            [results addObject:[NSURL URLWithString: url]];
            [resultsLock unlock];
            [anObject performSelectorOnMainThread: aSelector
                                       withObject: [[results copy] autorelease]
                                    waitUntilDone: NO];
        }
    }
    CFRelease(searchArray);
    CFRelease(searchGroup);
    CFRelease(searchResults);
    searching = NO;
    // Inefficient, I know, but I need to make the calling thread aware that
    // we're done searching.
    [anObject performSelectorOnMainThread: aSelector
                               withObject: [[results copy] autorelease]
                            waitUntilDone: NO];
    [pool release];
    [searchLock unlock];
}

- (void) index:(NSDictionary *)indexDict
{
    //!! I should add a conditional indexing lock around all of this so
    // we only have one indexing thread going at once.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id anObject = [indexDict objectForKey:@"anObject"];
    SEL aSelector = 
        NSSelectorFromString([indexDict objectForKey:@"aSelector"]);
    NSArray *urls = [indexDict objectForKey:@"urls"];
    
    if (!urls) {
        [pool release];
        return;
    }
    indexing = YES;
    [anObject performSelectorOnMainThread: aSelector
                               withObject: nil
                            waitUntilDone: NO];
    
    NSEnumerator *urlsEnum = [urls objectEnumerator];
    NSURL *currentURL;
    while ((currentURL = [urlsEnum nextObject]) != nil) {
        //!! I'm not comfortable just assuming UTF-8 here. Unfortunately,
        // NSURLResponse textEncoding: gets you an NSString rather than an
        // NSStringEncoding. I don't know how to convert between the two yet.
        NSData *returnData = 
            [self sendRequestForURI: currentURL 
                   usingCachePolicy: NSURLRequestReloadIgnoringCacheData];
        NSString *contents = 
            [[NSString alloc] initWithData: returnData
                                  encoding: NSUTF8StringEncoding];

        [self addDocumentToIndex: currentURL
                     withContent: contents];
    }
    indexing = NO;
    [anObject performSelectorOnMainThread: aSelector
                               withObject: nil
                            waitUntilDone: NO];
    [pool release];
}


- (NSData *) sendRequestForURI: (NSURL *) apiURL 
              usingCachePolicy: (NSURLRequestCachePolicy) cachePolicy 
{
    NSMutableURLRequest *req = 
        [NSMutableURLRequest requestWithURL: apiURL 
                                cachePolicy: cachePolicy 
                            timeoutInterval: kREQUEST_TIMEOUT_INTERVAL];
	
    [req setValue: kUSER_AGENT forHTTPHeaderField: kUSER_AGENT_HTTP_HEADER];
    
    NSURLResponse *resp;
    NSError *error;
	
	NSData *returnData = [NSURLConnection sendSynchronousRequest: req 
                                               returningResponse: &resp 
                                                           error: &error];
	
	if (error) { 
		NSLog(@"%@", error);
	}
	
	return returnData;
}
@end
