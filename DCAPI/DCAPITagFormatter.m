//
//  DCAPITagFormatter.m
//  Delicious Client
//
//  Created by Laurence Andersen on Mon Aug 16 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPITagFormatter.h"


@implementation DCAPITagFormatter

- (NSString *) stringForObjectValue: (id) anObject {
	if ([anObject isKindOfClass: [DCAPITag class]]) {
		return [NSString stringWithFormat: @"%@ (%d)", [anObject name], [[(DCAPITag *) anObject count] intValue]];
    }
	else if ([anObject isKindOfClass: [NSString class]]) {
		return anObject;
	}
	
	return nil;
}

- (NSString *) editingStringForObjectValue: (id) anObject {
	if ([anObject isKindOfClass: [DCAPITag class]]) {
		return [anObject name];
    }
	else if ([anObject isKindOfClass: [NSString class]]) {
		return anObject;
	}
	
	return nil;
}

- (BOOL) getObjectValue: (id *) anObject forString: (NSString *) string errorDescription: (NSString **) error {
	*anObject = [[[DCAPITag alloc] initWithName: string count: 0] autorelease];
	return YES;
}

@end
