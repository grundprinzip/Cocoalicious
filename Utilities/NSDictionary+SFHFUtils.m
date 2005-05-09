//
//  NSDictionary+SFHFUtils.m
//  Delicious Client
//
//  Created by Laurence Andersen on Thu May 05 2005.
//  Copyright (c) 2005 Sci-Fi Hi-Fi. All rights reserved.
//

#import "NSDictionary+SFHFUtils.h"


@implementation NSDictionary (SFHFUtils)

- (id) initWithObjects: (NSArray *) objects keyName: (NSString *) keyName {
	if (self = [super init]) {
		NSEnumerator *objectEnumerator = [objects objectEnumerator];
		id currentKey;
		id currentValue;
		NSMutableArray *keys = [[NSMutableArray alloc] init];
		NSMutableArray *values = [[NSMutableArray alloc] init];
		
		while ((currentValue = [objectEnumerator nextObject]) != nil) {
			if ((currentKey = [currentValue valueForKey: keyName]) != nil) {
				[keys addObject: currentKey];
				[values addObject: currentValue];
			}
		}
		
		return [self initWithObjects: [values autorelease] forKeys: [keys autorelease]];
	}
	else {
		return nil;
	}
}

@end
