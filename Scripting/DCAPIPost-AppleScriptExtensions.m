//
//  DCAPIPost-AppleScriptExtensions.m
//  Delicious Client
//
//  Created by Armin Briegel on 18.11.2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "DCAPIPost-AppleScriptExtensions.h"

#import "AppController.h"
#import "AppController-AppleScriptExtensions.h"

@implementation DCAPIPost (AppleScriptExtensions)

- (NSScriptObjectSpecifier *) objectSpecifier {
	AppController *appController = (AppController *)[NSApp delegate];
	NSIndexSpecifier *specifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription: (NSScriptClassDescription *)[NSApp classDescription] containerSpecifier: [NSApp objectSpecifier] key: @"orderedPosts"];
	[specifier setIndex: [appController indexOfObjectInOrderedPosts: self]];
	//NSLog(@"[DCAPIPost objectSpecifier]");
	return [specifier autorelease];
}


- (void) setURLAsString: (NSString *) newURLString {
	[self setURL: [NSURL URLWithString: newURLString]];
}
- (NSString *) URLAsString {
	return [[self URL] absoluteString];
}

- (void) setTagsAsString: (NSString *)newString {
	[self setTagsFromString: newString];
}

@end
