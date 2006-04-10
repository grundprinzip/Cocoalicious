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
	NSMutableArray *tags;
	NSString *urlHash;
	NSNumber *rating;
	NSNumber *visitCount;
	BOOL isPrivate;
}

- initWithURL: (NSURL *) newURL description: (NSString *) newDescription extended: (NSString *) newExtended date: (NSDate *) newDate tags: (NSArray *) newTags urlHash: (NSString *) newHash isPrivate: (BOOL) newIsPrivate;
- (void) setDescription: (NSString *) description;
- (NSString *) description;
- (void) setDate: (NSDate *) newDate;
- (NSDate *) date;
- (void) setURL: (NSURL *) newURL;
- (NSString *) extended;
- (void) setExtended: (NSString *) newExtended;
- (NSURL *) URL;
- (NSString *) URLString;
- (void) setTagsFromString: (NSString *) tagString;
- (NSString *) tagsAsString;
- (void) setTags: (NSArray *) newTags;
- (void) addTagsFromRating: (NSNumber *) rating;
- (NSMutableArray *) tags;
- (void) addTagNamed: (NSString *) newTagName;
- (void) removeTagNamed: (NSString *) removeTagName;
- (void) renameTag: (NSString *) oldTagName to: (NSString *) newTagName;
- (void) setURLHash: (NSString *) newHash;
- (NSString *) urlHash;
- (BOOL) matchesSearch: (NSString *) keyword extended: (BOOL) searchExtended tags: (NSArray *) matchTags matchKeywordsAsTags: (BOOL) matchKeywordsAsTags URIs: (BOOL) searchURIs;
- (BOOL) matchesTags: (NSArray *) matchTags;
- (NSNumber *) rating;
- (void) setRating: (NSNumber *) rating;
- (void) calculateRatingFromTags;
- (void) clearRatingTags;
- (int) findIndexOfNextRatingTagAfterIndex: (int) index;
- (void) setVisitCount: (NSNumber *) newVisitCount;
- (NSNumber *) visitCount;
- (void) incrementVisitCount;
- (BOOL) isPrivate;
- (void) setPrivate: (BOOL) newIsPrivate;

- (id) initWithCoder:(NSCoder *) coder;
- (void) encodeWithCoder:(NSCoder *) coder;

+ (DCAPIPost *) postWithDictionary: (NSDictionary *) postDictionary URL: (NSURL *) URL;
- (NSDictionary *) dictionaryRepresentation;

@end
