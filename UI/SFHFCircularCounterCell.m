//
//  SFHFCircularCounterCell.m
//  Delicious Client
//
//  Created by Buzz Andersen on 5/29/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SFHFCircularCounterCell.h"


@implementation SFHFCircularCounterCell

- (void) drawInteriorWithFrame: (NSRect) cellFrame inView: (NSView *) controlView {
	NSRect textRect = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame), cellFrame.size.width - 13, cellFrame.size.height);
	[[self attributedStringValue] drawInRect: textRect];

    NSRect circleRect = NSMakeRect(NSMaxX(cellFrame) - 12, NSMaxY(cellFrame) - 13, 10, 10);
	
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect: circleRect];	
	
	if ([self isHighlighted]) {
		[[NSColor whiteColor] set];
	}
	else {
		[[NSColor grayColor] set];
	}
	
	[circle fill];
}

@end
