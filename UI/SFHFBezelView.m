//
//  SFHFBezelView.m
//  Delicious Client
//
//  Created by Laurence Andersen on Sat Aug 28 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFBezelView.h"


@implementation SFHFBezelView

- (void) drawRect: (NSRect) rect {
	[super drawRect: rect];
	
	NSRect frame = [self bounds];

	/* Turn off anti-aliasing */
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	
	/* Draw top bezel */
	[[NSColor colorWithCalibratedRed: 0.576471 green: 0.576471 blue: 0.576471 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.size.width - 2, frame.size.height - 1) toPoint: NSMakePoint(frame.origin.x + 1, frame.size.height - 1)];
	
	[[NSColor colorWithCalibratedRed: 0.400000 green: 0.400000 blue: 0.400000 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.size.width - 2, frame.size.height - 2) toPoint: NSMakePoint(frame.origin.x + 1, frame.size.height - 2)];

	/* Draw left and right bezels */
	[[NSColor colorWithCalibratedRed: 0.878431 green: 0.878431 blue: 0.878431 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.origin.x, frame.origin.y + 1) toPoint: NSMakePoint(frame.origin.x, frame.size.height - 2)];
	[NSBezierPath strokeLineFromPoint: NSMakePoint((frame.origin.x + frame.size.width) - 1, frame.origin.y + 1) toPoint: NSMakePoint((frame.origin.x + frame.size.width) - 1, frame.size.height - 2)];
	
	[[NSColor colorWithCalibratedRed: 0.400000 green: 0.400000 blue: 0.400000 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.origin.x + 1, frame.origin.y + 1) toPoint: NSMakePoint(frame.origin.x + 1, frame.size.height - 2)];
	[NSBezierPath strokeLineFromPoint: NSMakePoint((frame.origin.x + frame.size.width) - 2, frame.origin.y + 1) toPoint: NSMakePoint((frame.origin.x + frame.size.width) - 2, frame.size.height - 2)];

	/* Draw bottom bezel */
	[[NSColor colorWithCalibratedRed: 0.941176 green: 0.941176 blue: 0.941176 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.size.width - 2, frame.origin.y) toPoint: NSMakePoint(frame.origin.x + 1, frame.origin.y)];
	
	[[NSColor colorWithCalibratedRed: 0.400000 green: 0.400000 blue: 0.400000 alpha: 1.0] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(frame.size.width - 2, frame.origin.y + 1) toPoint: NSMakePoint(frame.origin.x + 1, frame.origin.y + 1)];
		
	[[NSGraphicsContext currentContext] setShouldAntialias: YES];
}

@end
