//
//  NSArray+IndexSetAdditions.m
//  Delicious Client
//
//  Created by Buzz Andersen on 9/10/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NSArray+IndexSetAdditions.h"


@implementation NSArray (IndexSetAddition)

- (NSArray *) subarrayWithIndexes: (NSIndexSet *)indexes
{
    NSMutableArray *targetArray  = [NSMutableArray array];
    unsigned count = [self count];

    unsigned index = [indexes firstIndex];
    while ( index != NSNotFound )
    {
        if ( index < count )
            [targetArray addObject: [self objectAtIndex: index]];
            
        index = [indexes indexGreaterThanIndex: index];
    }

    return targetArray;
}

@end