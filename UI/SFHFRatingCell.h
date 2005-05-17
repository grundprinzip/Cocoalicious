//
//  SFHFRatingCell.h
//  TableManagerTest
//
//  Created by Buzz Andersen on Mon Feb 23 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SFHFRatingCell : NSActionCell <NSCopying, NSCoding> {
    NSRect currentFrameInControlView;
    NSImage *highlightedImage;
    NSNumber *maximumRating;
}

- (void) setHighlightedImage: (NSImage *) newHighlightedImage;
- (NSImage *) highlightedImage;
- (void) setMaximumRating: (NSNumber *) newMaximumRating;
- (NSNumber *) maximumRating;

- (NSNumber *) calculateRatingForPoint: (NSPoint) point inView: (NSView *) controlView;

@end
