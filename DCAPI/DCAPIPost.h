//
//  DCAPIPost.h
//  Delicious Client
//
//  Created by Buzz Andersen on Wed Jan 28 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"


@interface DCAPIPost : NSObject <NSCoding> {
    NSURL *URL;
    NSString *description;
    NSString *extended;
    NSDate *date;
	NSArray *tags;
	NSString *urlHash;
}

- initWithURL: (NSURL *) newURL description: (NSString *) newDescription extended: (NSString *) newExtended date: (NSDate *) newDate tags: (NSArray *) newTags urlHash: (NSString *) newHash;
- (void) setDescription: (NSString *) description;
- (NSString *) description;
- (void) setDate: (NSDate *) newDate;
- (NSDate *) date;
- (void) setURL: (NSURL *) newURL;
- (NSString *) extended;
- (void) setExtended: (NSString *) newExtended;
- (NSURL *) URL;
- (void) setTagsFromString: (NSString *) tagString;
- (NSString *) tagsAsString;
- (void) setTags: (NSArray *) newTags;
- (NSArray *) tags;
- (void) setURLHash: (NSString *) newHash;
- (NSString *) urlHash;
- (BOOL) matchesSearch: (NSString *) keyword extended: (BOOL) searchExtended tags: (NSArray *) matchTags matchKeywordsAsTags: (BOOL) matchKeywordsAsTags URIs: (BOOL) searchURIs;
- (BOOL) matchesTags: (NSArray *) matchTags;

- (id) initWithCoder:(NSCoder *) coder;
- (void) encodeWithCoder:(NSCoder *) coder;

@end
