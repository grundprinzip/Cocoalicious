//
//  FullTextIndex.h
//  Delicious Client
//
//  Created by Andrew Wooster on Sat Oct 16 2004.
//  Copyright (c) 2004 Andrew Wooster. All rights reserved.
//
//  Many thanks to people who've tread this ground before. The Adium Logger
//  plugin and trailblazer web browser were both helpful references.

// NOTES:
// - It would be nice if Apple allowed the text extractors to be used
//   explicitly on NSData.
// - I should make kTEXT_INDEX_NAME include the username.
// - The View/Index menu item shouldn't be enabled until there's something to
//   index on.
// - I need to filter out the HTML in text given to addDocumentToIndex.

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "defines.h"

@interface FullTextIndex : NSObject {
    // The Search Kit index of html content.
    SKIndexRef textIndex;
    BOOL
        // Object is currently performing a search.
        searching,
        // Object is currently indexing documents.
        indexing;
    
    // A lock on the index while searching or updating.
    NSLock *indexLock;
    
    // The NSURL results array.
    NSMutableArray *results;
    // A lock on results.
    NSLock *resultsLock;
    
    // The ID of the current search. When a new search comes in,
    // we should increment the search id so the object knows to quit the
    // old search and start on a new one.
    int currentSearchID;
    // A lock while searching.
    NSLock *searchLock;
}

// Accessor for the Search Kit index.
- (SKIndexRef) textIndex;
- (void) openIndex;
- (void) closeIndex;
- (void) flushIndex;
- (NSString *) indexPath;

// Accessor for the Search Kit result.
- (NSMutableArray *)results;
- (BOOL)indexing;
- (BOOL)searching;

- (void) addDocumentToIndex:(NSURL *)url
                withContent:(NSString *)content;
- (void) search: (NSDictionary *)searchDict;

- (void) index: (NSDictionary *)indexDict;

- (NSData *) sendRequestForURI: (NSURL *)apiURL 
              usingCachePolicy: (NSURLRequestCachePolicy)cachePolicy;

- (void) logIndexInformation;
@end
