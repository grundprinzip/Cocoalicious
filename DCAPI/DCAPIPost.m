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

- initWithURL: (NSURL *) newURL description: (NSString *) newDescription extended: (NSString *) newExtended date: (NSDate *) newDate tags: (NSArray *) newTags hash: (NSString *) newHash {
    [super init];
    
    [self setURL: newURL];
    [self setDescription: newDescription];
    [self setExtended: newExtended];
    [self setDate: newDate];
	[self setTags: newTags];
	[self setHash: newHash];
    
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

- (void) setHash: (NSString *) newHash {
    if (hash != newHash) {
        [hash release];
        hash = [newHash copy];
    }
}

- (NSString *) hash {
	return [[hash retain] autorelease];
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
	[self setExtended: [coder decodeObjectForKey: @"extendend"]];
	[self setDate: [coder decodeObjectForKey: @"date"]];
	[self setTags: [coder decodeObjectForKey: @"tags"]];
	[self setHash: [coder decodeObjectForKey: @"hash"]];
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder {
	[coder encodeObject: URL forKey: @"URL"];
	[coder encodeObject: description forKey: @"description"];
	[coder encodeObject: extended forKey: @"extended"];
	[coder encodeObject: date forKey: @"date"];
	[coder encodeObject: tags forKey: @"tags"];
	[coder encodeObject: hash forKey: @"hash"];
}

- (void) dealloc {
    [URL release];
    [description release];
    [extended release];
    [date release];
	[tags release];
	[hash release];
    [super dealloc];
}

@end
