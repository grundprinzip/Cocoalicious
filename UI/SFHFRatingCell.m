//
//  SFHFRatingCell.m
//
//  Created by Buzz Andersen on Mon Feb 23 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFRatingCell.h"

/* TO DO
- Space holder images
- Make sure this works correctly with NSCoding
- Make it so that insets are not hard coded
*/

#define kMarkerInset 2
#define kMarkerSpacing 1
#define kHighlightedImageCoderKey (@"HighlightedImage")
#define kMaximumRatingCoderKey (@"MaximumRating")


@implementation SFHFRatingCell

- (id) copyWithZone: (NSZone *) zone {
    SFHFRatingCell *cellCopy = [super copyWithZone: zone];

    /* Assume that other initialization takes place here. */
    cellCopy->highlightedImage = nil;
    [cellCopy setHighlightedImage: [self highlightedImage]];
    cellCopy->maximumRating = nil;
    [cellCopy setMaximumRating: [self maximumRating]];

    return cellCopy;
}

- (id) initWithCoder: (NSCoder *) decoder {
    self = [super initWithCoder: decoder];
    
    highlightedImage = [[decoder decodeObjectForKey: kHighlightedImageCoderKey] retain];
    maximumRating = [[decoder decodeObjectForKey: kMaximumRatingCoderKey] retain];
    
    return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder {
    [super encodeWithCoder: encoder];
    
    [encoder encodeObject: [self highlightedImage] forKey: kHighlightedImageCoderKey];
    [encoder encodeObject: [self maximumRating] forKey: kMaximumRatingCoderKey];
    
    return;
}

- (void) setHighlightedImage: (NSImage *) newHighlightedImage {
    if (highlightedImage != newHighlightedImage) {
        [highlightedImage release];
        highlightedImage = [newHighlightedImage copy];
    }
}

- (NSImage *) highlightedImage {
    return [[highlightedImage retain] autorelease];
}

- (void) setMaximumRating: (NSNumber *) newMaximumRating {
    if (maximumRating != newMaximumRating) {
        [maximumRating release];
        maximumRating = [newMaximumRating copy];
    }
}

- (NSNumber *) maximumRating {
    return [[maximumRating retain] autorelease];
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame inView: (NSView *) controlView {    
    NSImage *ratingImage = [self highlightedImage];
    
    if ([self isHighlighted] && [self highlightedImage]) {
        ratingImage = [self highlightedImage];
    }
    else {
        ratingImage = [self image];
    }
    
    NSNumber *ratingNumber = [self objectValue];

    if (!ratingImage || !ratingNumber || [ratingNumber intValue] < 1) {
        return;
    }    

    [controlView lockFocus];
    
    [ratingImage setFlipped: [controlView isFlipped]];

    int i;
    
    NSRect currentRect = NSMakeRect(NSMinX(cellFrame) + kMarkerInset, NSMinY(cellFrame) + kMarkerInset, [ratingImage size].width, [ratingImage size].height);
    
    for (i = 1; i <= [ratingNumber intValue]; i++) {
        if (NSIntersectsRect(currentRect, cellFrame)) {
            NSRect intersectRect = NSIntersectionRect(currentRect, cellFrame);

            [ratingImage drawInRect: intersectRect fromRect: NSMakeRect(0, 0, NSWidth(intersectRect), NSHeight(intersectRect)) operation: NSCompositeSourceOver fraction: 1.0];
        }

        currentRect = NSOffsetRect(currentRect, [ratingImage size].width + kMarkerSpacing, 0);
    }

    [controlView unlockFocus];
}

- (BOOL) trackMouse: (NSEvent *) theEvent inRect: (NSRect) cellFrame ofView: (NSView *) controlView untilMouseUp: (BOOL) untilMouseUp {
    currentFrameInControlView = [self drawingRectForBounds: cellFrame];
    return [super trackMouse: theEvent inRect: cellFrame ofView: controlView untilMouseUp: untilMouseUp];
}

- (BOOL) startTrackingAt: (NSPoint) startPoint inView: (NSView *) controlView {
    [super startTrackingAt: startPoint inView: controlView];
    return YES;
}

- (BOOL) continueTracking: (NSPoint) lastPoint at: (NSPoint) currentPoint inView: (NSView *) controlView {
    if ([super continueTracking: lastPoint at: currentPoint inView: controlView]) {
        [self setObjectValue: [self calculateRatingForPoint: currentPoint inView: controlView]];
    }
    
    return YES;
}

- (void) stopTracking: (NSPoint) lastPoint at: (NSPoint) stopPoint inView: (NSView *) controlView mouseIsUp: (BOOL) flag {
    [self setObjectValue: [self calculateRatingForPoint: stopPoint inView: controlView]];	
    [super stopTracking: lastPoint at: stopPoint inView: controlView mouseIsUp: flag];
}

- (NSNumber *) calculateRatingForPoint: (NSPoint) point inView: (NSView *) controlView {
    NSImage *ratingImage = [self image];
    
    if (!ratingImage) {
        return [NSNumber numberWithInt: 0];
    }
    
    float zeroX = NSMinX([self drawingRectForBounds: currentFrameInControlView]) + kMarkerInset;
    
    NSNumber *rating = [NSNumber numberWithInt: ceil((point.x - zeroX) / ([ratingImage size].width + 1))];
    NSNumber *maxRating = [self maximumRating];
    
    if (maxRating && [rating compare: maxRating] == NSOrderedDescending) {
        return maxRating;
    }
    
    return rating;
}

- (void) dealloc {
    [highlightedImage release];
    [maximumRating release];
    [super dealloc];
}

@end
