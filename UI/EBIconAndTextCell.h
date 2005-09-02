//
//  EBIconAndTextCell.h
//  Delicious Client
//
//  Created by Eric Blair on 6/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EBIconAndTextCell : NSTextFieldCell <NSCopying, NSCoding> {
	NSImage		*favicon;
	NSString	*description;
	NSSize		iconSize;
}

- (id)initWithDefaultIcon: (NSImage *)newDefaultIcon;

- (id)initWithFavIconPath: (NSString *)newFavIconPath
	description: (NSString *)newDescription
	iconSize: (NSSize)newIconSize
	defaultIcon: (NSImage *)newDefaultIcon;

- (void)setFavicon: (NSImage *)newFavicon;
- (NSImage* )favicon;
- (void)setDescription: (NSString *)newDescription;
- (NSString *)description;
- (void)setIconSize:(NSSize)newIconSize;
- (NSSize)iconSize;

@end
