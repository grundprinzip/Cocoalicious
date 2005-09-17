//
//  SFHFTableHeaderCell.m
//  Delicious Client
//
//  Created by Laurence Andersen on Sun Aug 29 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFTableHeaderCell.h"


@implementation SFHFTableHeaderCell

- (id) copyWithZone: (NSZone *) zone {
    SFHFTableHeaderCell *cellCopy = [super copyWithZone: zone];

    cellCopy->backgroundTexture = nil;
    [cellCopy setBackgroundTexture: [self backgroundTexture]];
	
	[cellCopy setBorderStyle: [self borderStyle]];
	[cellCopy setTextStyle: [self textStyle]];
	[cellCopy setTextAlignment: [self textAlignment]];

    return cellCopy;
}

- (id) initWithCoder: (NSCoder *) decoder {
    self = [super initWithCoder: decoder];    

    [self setBackgroundTexture: [decoder decodeObjectForKey: @"texturedBackgroundCoderKey"]];
	[self setBorderStyle: [(NSNumber *) [decoder decodeObjectForKey: @"borderStyleCoderKey"] intValue]];
	[self setTextStyle: [(NSNumber *) [decoder decodeObjectForKey: @"textStyleCoderKey"] intValue]];
	[self setTextAlignment: [(NSNumber *) [decoder decodeObjectForKey: @"textAlignmentCoderKey"] intValue]];

    return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder {
    [super encodeWithCoder: encoder];
    [encoder encodeObject: [self backgroundTexture] forKey: @"texturedBackgroundCoderKey"];
	[encoder encodeObject: [NSNumber numberWithInt: [self borderStyle]] forKey: @"borderStyleCoderKey"];
	[encoder encodeObject: [NSNumber numberWithInt: [self textStyle]] forKey: @"textStyleCoderKey"];
	[encoder encodeObject: [NSNumber numberWithInt: [self textAlignment]] forKey: @"textAlignmentCoderKey"];
}

- (void) drawWithFrame: (NSRect) inFrame inView: (NSView*) inView {
	NSImage *texturedBackground = [self backgroundTexture];

	[super drawWithFrame: inFrame inView: inView];

	if (texturedBackground) {
		NSRect tempSrc = NSZeroRect;
		tempSrc.origin.y = 0.0;
		tempSrc.size = [texturedBackground size];
		tempSrc.size.height = [texturedBackground size].height - 1.0;
    
		NSRect tempDst = inFrame;
		tempDst.origin.y = 1.0;
		tempDst.size.height = inFrame.size.height - 2.0;
    
		[texturedBackground drawInRect: tempDst fromRect: tempSrc operation: NSCompositeSourceOver fraction: 1.0];
	}
	
	if ([self borderStyle] == SFHFiTunesTableHeaderCellBorderStyle) {
		/* Turn off anti-aliasing */
		[[NSGraphicsContext currentContext] setShouldAntialias: NO];

		[[NSColor colorWithCalibratedRed: 0.400000 green: 0.400000 blue: 0.400000 alpha: 1.0] set];
		[NSBezierPath strokeLineFromPoint: NSMakePoint(inFrame.origin.x, inFrame.origin.y + 1) toPoint: NSMakePoint(inFrame.origin.x + inFrame.size.width, inFrame.origin.y + 1)];	
		[NSBezierPath strokeLineFromPoint: NSMakePoint(inFrame.origin.x, inFrame.origin.y + inFrame.size.height) toPoint: NSMakePoint(inFrame.origin.x + inFrame.size.width, inFrame.origin.y + inFrame.size.height)];

		/* Turn on anti-aliasing */
		[[NSGraphicsContext currentContext] setShouldAntialias: YES];
	}

	if (![self stringValue] || [[self stringValue] length] < 1) {
		return;
	}

	NSAttributedString *attrString = [self attributedStringValue];
	NSDictionary *attrDictionary = [attrString attributesAtIndex: 0 effectiveRange: NULL];
	NSMutableDictionary *attrs = [attrDictionary mutableCopy];
	
	NSRect alignedRect = inFrame;
    alignedRect.size = [[self stringValue] sizeWithAttributes: attrs];
	float offset = 0.5;
	
	if ([self textAlignment] == SFHFCenteredTableHeaderCellTextAlignment) {
		alignedRect.origin.x = ((inFrame.size.width - alignedRect.size.width) / 2.0) - offset;	
	}
	else {
		alignedRect.origin.x += 1.5;	
	}
		
	alignedRect.origin.y = ((inFrame.size.height - alignedRect.size.height) / 2.0) + offset;
	
	if ([self textStyle] == SFHFEmbossedTableHeaderCellTextStyle) {
		[attrs setValue: [NSColor colorWithCalibratedWhite: 0.8 alpha: 0.7] forKey: @"NSColor"];
		[[self stringValue] drawInRect: alignedRect withAttributes: attrs];
		
		[attrs setValue: [NSColor blackColor] forKey: @"NSColor"];
		alignedRect.origin.x += offset;
		alignedRect.origin.y -= offset;
		[[self stringValue] drawInRect: alignedRect withAttributes: attrs];
	}
	
	[attrs release];
}

- (NSImage *) backgroundTexture {
	return [[backgroundTexture retain] autorelease];
}

- (void) setBackgroundTexture: (NSImage *) newBackgroundTexture {
	if (backgroundTexture != newBackgroundTexture) {
		[backgroundTexture release];
		backgroundTexture = [newBackgroundTexture copy];
		[backgroundTexture setFlipped: YES];
	}
}

- (void) setTextStyle: (SFHFTableHeaderCellTextStyle) newTextStyle {
	textStyle = newTextStyle;
}

- (SFHFTableHeaderCellTextStyle) textStyle {
	return textStyle;
}

- (void) setBorderStyle: (SFHFTableHeaderCellBorderStyle) newBorderStyle {
	borderStyle = newBorderStyle;
}

- (SFHFTableHeaderCellBorderStyle) borderStyle {
	return borderStyle;
}

- (void) setTextAlignment: (SFHFTableHeaderCellTextAlignment) newTextAlignment {
	textAlignment = newTextAlignment;
}

- (SFHFTableHeaderCellTextAlignment) textAlignment {
	return textAlignment;
}

- (void) dealloc {
	[backgroundTexture release];
	[super dealloc];
}

@end
