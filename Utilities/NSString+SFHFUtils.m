//
//  NSString+SFHFUtils.m
//  Delicious Client
//
//  Created by Buzz Andersen on Fri May 14 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "NSString+SFHFUtils.h"


@implementation NSString (SFHFUtils)

- (NSString *) stringByUnescapingEntities: (NSDictionary *) entitiesDictionary {
    NSString *unescapedString = (NSString *) CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef) self, (CFDictionaryRef) entitiesDictionary);
    return [unescapedString autorelease];
}

- (NSString *) stringByAddingPercentEscapesUsingEncoding: (NSStringEncoding) encoding legalURLCharactersToBeEscaped: (NSString *) legalCharacters {
	NSString *escapedString = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) self, NULL, (CFStringRef) legalCharacters, CFStringConvertNSStringEncodingToEncoding(encoding));
	return [escapedString autorelease];
}

@end
