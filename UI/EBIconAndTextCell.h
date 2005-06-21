//
//  EBIconAndTextCell.h
//  Delicious Client
//
//  Created by Eric Blair on 6/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EBIconAndTextCell : NSTextFieldCell <NSCopying, NSCoding> {
	NSImage		*favIcon;
	NSString	*favIconPath;
	NSString	*description;
	NSSize		iconSize;
	NSImage		*defaultIcon;
	BOOL		regenFavIcon;
}

- (id)initWithDefaultIcon: (NSImage *)newDefaultIcon;

- (id)initWithFavIconPath: (NSString *)newFavIconPath
	description: (NSString *)newDescription
	iconSize: (NSSize)newIconSize
	defaultIcon: (NSImage *)newDefaultIcon;

- (void)setFavIcon: (NSImage *)newFavIcon;
- (NSImage* )favIcon;
- (void)setFavIconPath: (NSString *)newFavIconPath;
- (NSString *)favIconPath;
- (void)setDescription: (NSString *)newDescription;
- (NSString *)description;
- (void)setIconSize:(NSSize)newIconSize;
- (NSSize)iconSize;
- (void)setDefaultIcon: (NSImage *)newDefaultIcon;
- (NSImage *)defaultIcon;
- (void)setRegenFavIcon: (BOOL)newRegenFavIcon;
- (BOOL)regenFavIcon;

@end
