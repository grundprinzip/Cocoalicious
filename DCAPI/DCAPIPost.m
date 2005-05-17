//
//  DCAPIPost.m
//  Delicious Client
//
//  Created by Buzz Andersen on Wed Jan 28 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPIPost.h"

static NSString *kSEARCH_SEPARATOR_STRING = @" ";

@implementation DCAPIPost

- initWithURL: (NSURL *) newURL description: (NSString *) newDescription extended: (NSString *) newExtended date: (NSDate *) newDate tags: (NSArray *) newTags urlHash: (NSString *) newHash {
    [super init];
    
    [self setURL: newURL];
    [self setDescription: newDescription];
    [self setExtended: newExtended];
    [self setDate: newDate];
	[self setTags: newTags];
	[self setURLHash: newHash];
    
    return self;
}

- (void) setDate: (NSDate *) newDate {
    if (date != newDate) {
        [date release];
        date = [newDate copy];
    }
}

- (NSDate *) date {
    return [[date retain] autorelease];
}

- (void) setDescription: (NSString *) newDescription {
    if (description != newDescription) {
        [description release];
        description = [newDescription copy];
    }
}

- (NSString *) description {
    return [[description retain] autorelease];
}

- (void) setURL: (NSURL *) newURL {
    if (URL != newURL) {
        [URL release];
        URL = [newURL copy];
    }
}

- (NSURL *) URL {
    return [[URL retain] autorelease];
}

- (NSString *) URLString {
	return [URL absoluteString];
}

- (void) setExtended: (NSString *) newExtended {
    if (extended != newExtended) {
        [extended release];
        extended = [newExtended copy];
    }
}

- (NSString *) extended {
    return [[extended retain] autorelease];
}

- (void) setTagsFromString: (NSString *) tagString {
	if (tagString && [tagString length] > 0) {
		[self setTags: nil];
	}

	[self setTags: [tagString componentsSeparatedByString: kTAG_SEPARATOR]];
}

- (NSString *) tagsAsString {
	return [tags componentsJoinedByString: kTAG_SEPARATOR];
}

- (void) setTags: (NSArray *) newTags {
    if (tags != newTags) {
        [tags release];
        tags = [newTags mutableCopy];
		
		/* Figure out the post's rating based on the tags */
		[self setRating: [self calculateRatingFromTags: tags]];
	}	
}

- (NSNumber *) calculateRatingFromTags: (NSArray *) tagArray {
	NSEnumerator *tagEnum = [tagArray objectEnumerator];
	NSString *currentTag;
	NSCharacterSet *nonRatingCharSet = [[NSCharacterSet characterSetWithCharactersInString: kRATING_TAG_CHARACTER] invertedSet];
	
	unsigned int currentRating = 0;
	
	while ((currentTag = (NSString *) [tagEnum nextObject]) != nil) {
		NSScanner *scanner = [NSScanner scannerWithString: currentTag];
		NSString *ratingTag;
		
		if ([scanner scanUpToCharactersFromSet: nonRatingCharSet intoString: &ratingTag]) {				
			unsigned int numberOfStars;
			
			if (ratingTag && ((numberOfStars = [ratingTag length]) == [currentTag length]) && numberOfStars > currentRating) {
				currentRating = numberOfStars;
			}
		}
	}
	
	return [NSNumber numberWithUnsignedInt: currentRating];
}

- (NSArray *) tags {
	return [[tags retain] autorelease];
}

- (void) renameTag: (NSString *) oldTagName to: (NSString *) newTagName {
	if ([tags containsObject: oldTagName]) {
		[self addTagNamed: newTagName];
		[self removeTagNamed: oldTagName];
	}
}

- (void) addTagNamed: (NSString *) newTagName {
	if (newTagName) {
		[tags addObject: newTagName];
	}
}

- (void) removeTagNamed: (NSString *) removeTagName {
	if (removeTagName) {
		[tags removeObject: removeTagName];
	}
}

- (void) setURLHash: (NSString *) newHash {
    if (urlHash != newHash) {
        [urlHash release];
        urlHash = [newHash copy];
    }
}

- (NSString *) urlHash {
	return [[urlHash retain] autorelease];
}

- (NSNumber *) rating {
	if (!rating) {
		return [NSNumber numberWithInt: 0];
	}

	return [[rating retain] autorelease];
}

- (void) setRating: (NSNumber *) newRating {
	if (newRating != rating) {
		[rating release];
		rating = newRating;
	}
}

- (BOOL) matchesSearch: (NSString *) keyword extended: (BOOL) searchExtended tags: (NSArray *) matchTags matchKeywordsAsTags: (BOOL) matchKeywordsAsTags URIs: (BOOL) searchURIs {
	if (!keyword && !matchTags) {
		return YES;
	}

	if (matchTags) {
		if ([self matchesTags: matchTags]) {
			if (!keyword) {
				return YES;
			}
		}
		else {
			return NO;
		}
	}
		
	if (keyword) {
		NSString *keywordString = [keyword stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSArray *keywords = [keywordString componentsSeparatedByString: kSEARCH_SEPARATOR_STRING];

		NSRange range = [[self description] rangeOfString: keywordString options: NSCaseInsensitiveSearch];
		
		if (range.location != NSNotFound) {
			return YES;
		}
		
		if (matchKeywordsAsTags) {
			if ([self matchesTags: keywords]) {
				return YES;
			}
		}
		
		if ([self extended] && searchExtended) {
			range = [[self extended] rangeOfString: keywordString options: NSCaseInsensitiveSearch];

			if (range.location != NSNotFound) {
				return YES;
			}
		}

		if ([self URL] && searchURIs) {
			range = [[[self URL] absoluteString] rangeOfString: keywordString options: NSCaseInsensitiveSearch];
					
			if (range.location != NSNotFound) {
				return YES;
			}
		}
	}

	return NO;
}

- (BOOL) matchesTags: (NSArray *) matchTags {
	NSEnumerator *tagList = [[self tags] objectEnumerator];
	NSString *currentTag;

	int foundCount = 0;

	while ((currentTag = [tagList nextObject]) != nil) {
		int i;
		int max = [matchTags count];
		
		for (i = 0; i < max; i++) {
			NSString *matchTag = [matchTags objectAtIndex: i];
						
			if ([currentTag isEqualToString: matchTag]) {
				foundCount++;
			}
		}
		
		if (foundCount == max) {
			return YES;
		}
	}
	
	return NO;
}

- (id) initWithCoder:(NSCoder *) coder {
	[super init];
	[self setURL: [coder decodeObjectForKey: @"URL"]];
	[self setDescription: [coder decodeObjectForKey: @"description"]];
	[self setExtended: [coder decodeObjectForKey: @"extended"]];
	[self setDate: [coder decodeObjectForKey: @"date"]];
	[self setTags: [coder decodeObjectForKey: @"tags"]];
	[self setURLHash: [coder decodeObjectForKey: @"urlHash"]];
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder {
	[coder encodeObject: URL forKey: @"URL"];
	[coder encodeObject: description forKey: @"description"];
	[coder encodeObject: extended forKey: @"extended"];
	[coder encodeObject: date forKey: @"date"];
	[coder encodeObject: tags forKey: @"tags"];
	[coder encodeObject: urlHash forKey: @"urlHash"];
}

- (void) dealloc {
    [URL release];
    [description release];
    [extended release];
    [date release];
	[tags release];
	[urlHash release];
    [super dealloc];
}

// Overriden methods to support NSSet.
- (unsigned) hash
{
    return [[URL description] hash];
}

- (BOOL)isEqual: (id)anObject
{
    //!! Include respondsToSelector hash?
    if ([anObject hash] == [self hash]) {
        /* We need to special case here, because it's possible that two URL's
         * may have the same hash, but not actually be equal. The other 
         * direction (two URL's having different hashes, but actually being
         * equal) isn't possible, as far as I know. So, we check to see if
         * their description, which should be the full URL, is the same.
         * This also makes this test fairly safe if we get thrown objects
         * which aren't what we're expecting.
         */
        if (![[anObject description] isEqualToString: [URL description]]) {
            return NO;
        }
        return YES;
    } else {
        return NO;
    }
}

@end
