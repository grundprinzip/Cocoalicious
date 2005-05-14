//
//  DCAPITag.m
//  Delicious Client
//
//  Created by Buzz Andersen on Wed May 12 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPITag.h"


@implementation DCAPITag

- (id) copyWithZone: (NSZone *) zone {
    DCAPITag *tagCopy = [[DCAPITag allocWithZone: zone] init];

    tagCopy->name = nil;
    [tagCopy setName: [self name]];
    tagCopy->count = nil;
    [tagCopy setCount: [self count]];

    return tagCopy;
}

- initWithName: (NSString *) newName count: (NSNumber *) newCount {
    [super init];
    
    [self setName: newName];
    [self setCount: newCount];
    
    return self;
}

- (void) setName: (NSString *) newName {
    if (name != newName) {
        [name release];
        name = [newName copy];
    }
}

- (NSString *) name {
    return [[name retain] autorelease];
}

- (void) setCount: (NSNumber *) newCount {
    if (count != newCount) {
        [count release];
        count = [newCount copy];
    }
}

- (NSNumber *) count {
    return [[count retain] autorelease];
}

- (void) incrementCount {
	if (!count) {
		[self setCount: [NSNumber numberWithInt: 1]];
	}

	[self setCount: [NSNumber numberWithInt: [count intValue] + 1]];
}

- (void) decrementCount {
	if (!count) {
		return;
	}
	
	[self setCount: [NSNumber numberWithInt: [count intValue] - 1]];
}

- (NSString *) description {
    return [NSString stringWithFormat: @"%@ (%@)", [self name], [self count]];
}

- (void) dealloc {
    [name release];
    [count release];
    [super dealloc];
}

@end
