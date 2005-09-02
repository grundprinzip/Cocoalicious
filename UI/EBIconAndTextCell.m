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

@implementation EBIconAndTextCell

- (id)copyWithZone: (NSZone *)zone {
	EBIconAndTextCell * cellCopy = [super copyWithZone: zone];
	
	cellCopy->favicon = nil;
	[cellCopy setFavicon: [self favicon]];
	cellCopy->description = nil;
	[cellCopy setDescription: [self description]];
	[cellCopy setIconSize:[self iconSize]];
	
	return cellCopy;
}

- (id)initWithCoder: (NSCoder *)decoder {
	self = [super initWithCoder: decoder];
	
	favicon = nil;
	description = [[decoder decodeObjectForKey: kDescriptionCoderKey] retain];
	iconSize = [decoder decodeSizeForKey: kIconSizeKey];
	
	return self;
}

- (void)encodeWithCoder: (NSCoder*)encoder {
	[super encodeWithCoder: encoder];
		
	[encoder encodeObject: [self description] forKey: kDescriptionCoderKey];
	[encoder encodeSize: [self iconSize] forKey: kIconSizeKey];
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
		[self setIconSize: newIconSize];
	}
	
	return self;
}

- (void)dealloc
{
	[favicon release];
	[description release];
	
	[super dealloc];
}

- (NSSize)cellSize
{
	NSSize	cellSize = [super cellSize];
	NSSize	imageSize = NSZeroSize;
	NSSize	result = NSZeroSize;
		
	imageSize = [[self favicon] size];
	imageSize.width += kImageMargin;
	imageSize.height += kImageMargin;
		
	result.width = cellSize.width + imageSize.width;
	result.height = MAX(imageSize.height, result.height);
	
	return result;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSSize imageSize;
	NSRect imageFrame;
	
	imageSize = [[self favicon] size];
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
	
	NSImage *icon = [self favicon];
	
	if (icon) {
		[icon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
	
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)setFavicon: (NSImage *) newFavicon {
	if(favicon != newFavicon) {
		[favicon release];
		favicon = [newFavicon retain];
	}
}

- (NSImage* )favicon {
	return [[favicon retain] autorelease];
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

@end