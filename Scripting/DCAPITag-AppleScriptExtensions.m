//
//  DCAPITag-AppleScriptExtensions.m
//  Delicious Client
//
//  Created by Armin Briegel on 18.11.2004.
//

#import "DCAPITag-AppleScriptExtensions.h"

#import "AppController.h"
#import "AppController-AppleScriptExtensions.h"

@implementation DCAPITag (AppleScriptExtensions)

- (NSScriptObjectSpecifier *) objectSpecifier {
	NSNameSpecifier *specifier = [[NSNameSpecifier alloc] initWithContainerClassDescription: (NSScriptClassDescription *)[NSApp classDescription] containerSpecifier: [NSApp objectSpecifier] key: @"orderedTags"];
	[specifier setName: [self name]];
	//NSLog(@"[DCAPIPost objectSpecifier]");
	return [specifier autorelease];
}


@end
