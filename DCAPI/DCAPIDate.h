//
//  DCAPIDate.h
//  Delicious Client
//
//  Created by Buzz Andersen on Wed May 12 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"


@interface DCAPIDate : NSObject {
    NSCalendarDate *date;
    NSNumber *count;
}

- initWithDate: (NSCalendarDate *) newDate count: (NSNumber *) newCount;
- (void) setDate: (NSCalendarDate *) newDate;
- (NSCalendarDate *) date;
- (void) setCount: (NSNumber *) newCount;
- (NSNumber *) count;
- (NSString *) deliciousRepresentation;

@end
