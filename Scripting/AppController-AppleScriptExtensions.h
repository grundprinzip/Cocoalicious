//
//  AppController-AppleScriptExtensions.h
//  Delicious Client
//
//  Created by Armin Briegel on 18.11.2004.
//

#import <Cocoa/Cocoa.h>

#import "AppController.h"


@interface AppController (AppleScriptExtensions)

- (int) countOfOrderedPosts;
- (int) indexOfObjectInOrderedPosts: (id) object;
- (id) valueInOrderedPostsAtIndex: (int) index;
- (id) objectInOrderedPostsAtIndex: (int) index;

- (int) countOfOrderedTags;
- (int) indexOfObjectInOrderedTags: (id) object;
- (id) valueInOrderedTagsAtIndex: (int) index;
- (id) objectInOrderedTagsAtIndex: (int) index;

@end
