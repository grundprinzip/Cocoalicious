//
//  EBIconAndTextCell.m
//  Delicious Client
//
//  Created by Eric Blair on 6/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "EBIconAndTextCell.h"

#define kImageMargin				3.0
#define kFavIconPathCoderKey		(@"FavIconPath")
#define kDescriptionCoderKey		(@"Description")
#define	kIconSizeKey				(@"IconSize")
#define kDefaultIconCoderKey		(@"DefaultIconPath")

@interface EBIconAndTextCell (Private)
- (void)generateFavIcon;
@end

@implementation EBIconAndTextCell

- (id)copyWithZone: (NSZone *)zone {
	EBIconAndTextCell * cellCopy = [super copyWithZone: zone];
	
	cellCopy->favIcon = nil;
	[cellCopy setFavIcon: [self favIcon]];
	cellCopy->favIconPath = nil;
	[cellCopy setFavIconPath: [self favIconPath]];
	cellCopy->description = nil;
	[cellCopy setDescription: [self description]];
	[cellCopy setIconSize:[self iconSize]];
	cellCopy->defaultIcon = nil;
	[cellCopy setDefaultIcon: [self defaultIcon]];
	cellCopy->regenFavIcon = YES;
	[cellCopy setRegenFavIcon: [self regenFavIcon]];
	
	return cellCopy;
}

- (id)initWithCoder: (NSCoder *)decoder {
	self = [super initWithCoder: decoder];
	
	favIcon = nil;
	favIconPath = [[decoder decodeObjectForKey: kFavIconPathCoderKey] retain];
	description = [[decoder decodeObjectForKey: kDescriptionCoderKey] retain];
	iconSize = [decoder decodeSizeForKey: kIconSizeKey];
	defaultIcon = [[decoder decodeObjectForKey: kDefaultIconCoderKey] retain];
	regenFavIcon = YES;
	
	return self;
}

- (void)encodeWithCoder: (NSCoder*)encoder {
	[super encodeWithCoder: encoder];
		
	[encoder encodeObject: [self favIconPath] forKey: kFavIconPathCoderKey];
	[encoder encodeObject: [self description] forKey: kDescriptionCoderKey];
	[encoder encodeSize: [self iconSize] forKey: kIconSizeKey];
	[encoder encodeObject: [self defaultIcon] forKey: kDefaultIconCoderKey];
}

- (id)init {
	return [self initWithFavIconPath:@"" description:@"" iconSize:NSZeroSize defaultIcon:nil];
}

- (id)initTextCell: (NSString *)aText {
	return [self initWithFavIconPath:@"" description:aText iconSize:NSZeroSize defaultIcon:nil];
}

- (id)initImageCell: (NSImage *)anImage {
	return [self initWithFavIconPath:@"" description:@"" iconSize:NSZeroSize defaultIcon:nil];
}

- (id)initWithDefaultIcon: (NSImage *)newDefaultIcon {
	return [self initWithFavIconPath:@"" description:@"" iconSize:NSZeroSize defaultIcon:newDefaultIcon];
}

- (id)initWithFavIconPath: (NSString *)newFavIconPath
	description: (NSString *)newDescription
	iconSize: (NSSize)newIconSize
	defaultIcon: (NSImage *)newDefaultIcon {
	
	self = [super initTextCell:newDescription];
	
	if(self) {
		[self setFavIconPath: newFavIconPath];
		[self setIconSize: newIconSize];
		[self setDefaultIcon: newDefaultIcon]; 
	}
	
	return self;
}

- (void)dealloc
{
	[favIcon release];
	[favIconPath release];
	[description release];
	[defaultIcon release];
	
	[super dealloc];
}

- (NSSize)cellSize
{
	NSSize	cellSize = [super cellSize];
	NSSize	imageSize = NSZeroSize;
	NSSize	result = NSZeroSize;
	
	[self generateFavIcon];
	
	imageSize = [[self favIcon] size];
	imageSize.width += kImageMargin;
	imageSize.height += kImageMargin;
		
	result.width = cellSize.width + imageSize.width;
	result.height = MAX(imageSize.height, result.height);
	
	return result;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSSize imageSize;
	NSRect imageFrame;
	
	imageSize = [[self favIcon] size];
	NSDivideRect(cellFrame, &imageFrame, &cellFrame, 2*kImageMargin + imageSize.width, NSMinXEdge);
	if([self drawsBackground]) {
		[[self backgroundColor] set];
		NSRectFill(imageFrame);
	}
	imageFrame.origin.x += kImageMargin;
	imageFrame.size = imageSize;
	
	if([controlView isFlipped])
		imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
	else
		imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
	
	NSImage *icon = [self favIcon];
	
	if (!icon) {
		icon = [self defaultIcon];
	}
	
	[icon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)setFavIcon: (NSImage *)newFavIcon {
	if(favIcon != newFavIcon) {
		[favIcon release];
		favIcon = [newFavIcon copy];
	}
}

- (NSImage* )favIcon {
	return [[favIcon retain] autorelease];
}

- (void)setFavIconPath: (NSString *)newFavIconPath {
	if(favIconPath != newFavIconPath) {
		[favIconPath release];
		favIconPath = [newFavIconPath copy];
		
		// When we update the path, we should flag the favIcon for regen.
		[self setRegenFavIcon: YES];
	}
}

- (NSString *)favIconPath {
	return [[favIconPath retain] autorelease];
}

- (void)setDescription: (NSString *)newDescription {
	if(description != newDescription) {
		[description release];
		description = [newDescription copy];
	}
}

- (NSString *)description {
	return [[description retain] autorelease];
}


- (void)setIconSize:(NSSize)newIconSize
{
	iconSize = newIconSize;
}

- (NSSize)iconSize
{
	return iconSize;
}

- (void)setDefaultIcon: (NSImage *)newDefaultIcon {
	if(defaultIcon != newDefaultIcon) {
		[defaultIcon release];
		defaultIcon = [newDefaultIcon copy];
	}
}

- (NSImage *)defaultIcon {
	return [[defaultIcon retain] autorelease];
}

- (void)setRegenFavIcon:(BOOL)newRegenFavIcon {
	regenFavIcon = newRegenFavIcon;
}

- (BOOL)regenFavIcon {
	return regenFavIcon;
}

@end

@implementation EBIconAndTextCell (Private)

- (void)generateFavIcon {
	// Kick out if we have a fav icon and we don't need to regen
	if([self favIcon] != nil && ![self regenFavIcon])
		return;
	// Try to get a stored fav icon for the cell
	/*BOOL gotFavIcon = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self favIconPath]]) {
		[self setFavIcon: [[NSImage alloc] initWithContentsOfFile:[self favIconPath]]];
		// Check if the data at the given path could be converted to an NSImage
		gotFavIcon = ([self favIcon] != nil);
	}	
	// Fall back to the default icon
	if(!gotFavIcon)*/
		[self setFavIcon: [self defaultIcon]];
	
	if(NSEqualSizes([self iconSize], NSZeroSize) == NO) {
		[[self favIcon] setScalesWhenResized: NO];
		[[self favIcon] setSize: iconSize];
	}
	
	//[[self favIcon] setCacheMode: NSImageCacheAlways];
}

@end
