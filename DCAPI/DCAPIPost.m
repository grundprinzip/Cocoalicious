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
        tags = [newTags copy];
    }	
}

- (NSArray *) tags {
	return [[tags retain] autorelease];
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
		
		if (searchExtended) {
			range = [[self extended] rangeOfString: keywordString options: NSCaseInsensitiveSearch];

			if (range.location != NSNotFound) {
				return YES;
			}
		}

		if (searchURIs) {
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
    return [URL hash];
}

- (BOOL)isEqual: (id)anObject
{
    //!! Include respondsToSelector hash?
    if ([anObject hash] == [self hash]) {
        return YES;
    } else {
        return NO;
    }
}

@end
