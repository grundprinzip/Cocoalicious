//
//  DCAPIDate.m
//  Delicious Client
//
//  Created by Buzz Andersen on Wed May 12 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPIDate.h"


@implementation DCAPIDate

- init {
	if (self = [super init]) {
		[self setDate: [NSCalendarDate calendarDate]];
	}     
	
	return self;
}

- initWithDate: (NSCalendarDate *) newDate count: (NSNumber *) newCount {
    [self setDate: newDate];
    [self setCount: newCount];
    
    return self;
}

- (void) setDate: (NSCalendarDate *) newDate {
    if (date != newDate) {
        [date release];
        date = [newDate copy];
    }
}

- (NSCalendarDate *) date {
    return [[date retain] autorelease];
}

- (NSNumber *) count {
    return [[count retain] autorelease];
}

- (void) setCount: (NSNumber *) newCount {
    if (count != newCount) {
        [count release];
        count = [newCount copy];
    }
}

- (NSString *) deliciousRepresentation {
    return [[self date] descriptionWithCalendarFormat: kDEFAULT_DATE_FORMAT];
}

- (NSString *) description {
    return [[self deliciousRepresentation] stringByAppendingFormat: @" (%@)", [self count]];
}

- (void) dealloc {
    [date release];
    [count release];
    [super dealloc];
}

@end
