//
//  DCAPITag.h
//  Delicious Client
//
//  Created by Buzz Andersen on Wed May 12 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DCAPITag : NSObject <NSCopying> {
    NSString *name;
    NSNumber *count;
}

- initWithName: (NSString *) newName count: (NSNumber *) newCount;
- (void) setName: (NSString *) newName;
- (NSString *) name;
- (void) setCount: (NSNumber *) newCount;
- (NSNumber *) count;
- (void) incrementCount;
- (void) decrementCount;

@end
