//
//  DCAPIPost-AppleScriptExtensions.h
//  Delicious Client
//
//  Created by Armin Briegel on 18.11.2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DCAPIPost.h"

@interface DCAPIPost (AppleScriptExtensions)

- (void) setURLAsString: (NSString *) newURLString;
- (NSString *) URLAsString;


@end
