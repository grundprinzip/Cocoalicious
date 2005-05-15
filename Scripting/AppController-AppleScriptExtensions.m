//
//  AppController-AppleScriptExtensions.m
//  Delicious Client
//
//  Created by Armin Briegel on 18.11.2004.
//

#import "AppController-AppleScriptExtensions.h"


@implementation AppController (AppleScriptExtensions)

#pragma mark Indexed Accessor Methods

/* To hide the internal accessor methods from AppleScript we add different accessor methods under the name 'orderedPosts' here.
This also should make it easier to change storage method in the future. */

- (int) countOfOrderedPosts {
	return [[self posts] count];
}

- (int) indexOfObjectInOrderedPosts: (id) object {
	return [[self postsArray] indexOfObject: object];
}

- (id) valueInOrderedPostsAtIndex: (int) index {
	if (index < [self countOfOrderedPosts]) {
		return [[self postsArray] objectAtIndex: index];
	} else {
		return nil;
	}
}

- (id) objectInOrderedPostsAtIndex: (int) index {
	return [self valueInOrderedPostsAtIndex: index];
}

- (void) insertInOrderedPosts: (id) newPost{
	// insert current date if not set by the script
	if (![newPost date]) [newPost setDate:[NSCalendarDate date]];
	[[self client] addPost: newPost];
	[self refresh: self];
}

- (void) insertInOrderedPosts: (id) newPost atIndex: (int) index {
	// we have to ignore the index, as de.icio.us API does not support this
	[self insertInOrderedPosts: newPost];
}

- (void) removeFromOrderedPostsAtIndex: (int) index {
	DCAPIPost *post = (DCAPIPost *)[self valueInOrderedPostsAtIndex: index];
	[[self client] deletePostWithURL: [post URL]];
	[self refresh: self];
}


- (int) countOfOrderedTags {
	return [[self tags] count];
}

- (int) indexOfObjectInOrderedTags: (id) object {
	return [[self tagsArray] indexOfObject: object];
}

- (id) valueInOrderedTagsAtIndex: (int) index {
	if (index < [self countOfOrderedTags]) {
		return [[self tagsArray] objectAtIndex: index];
	} else {
		return nil;
	}
}

- (id) objectInOrderedTagsAtIndex: (int) index {
	return [self valueInOrderedTagsAtIndex: index];
}

#pragma mark Application Delegate Methods

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	//NSLog(@"[AppController delegateHandlesKey: %@]", key);
	if ([key isEqualToString: @"orderedPosts"]) {
		return YES;
	} else if ([key isEqualToString:@"orderedTags"]) {
		return YES;
	} else {
		return NO;		
	}
}

@end
