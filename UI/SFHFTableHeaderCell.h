//
//  SFHFTableHeaderCell.h
//  Delicious Client
//
//  Created by Laurence Andersen on Sun Aug 29 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum { 
    SFHFDefaultTableHeaderCellTextStyle = 0, 
    SFHFEmbossedTableHeaderCellTextStyle = 1
} SFHFTableHeaderCellTextStyle;

typedef enum { 
    SFHFDefaultTableHeaderCellBorderStyle = 0, 
    SFHFiTunesTableHeaderCellBorderStyle = 1
} SFHFTableHeaderCellBorderStyle;

typedef enum {
	SFHFDefaultTableHeaderCellTextAlignment = 0,
	SFHFCenteredTableHeaderCellTextAlignment = 1
} SFHFTableHeaderCellTextAlignment;

@interface SFHFTableHeaderCell : NSTableHeaderCell <NSCopying, NSCoding> {
	NSImage *backgroundTexture;
	SFHFTableHeaderCellTextStyle textStyle;
	SFHFTableHeaderCellBorderStyle borderStyle;
	SFHFTableHeaderCellTextAlignment textAlignment;
}

- (NSImage *) backgroundTexture;
- (void) setBackgroundTexture: (NSImage *) newBackgroundTexture;
- (void) setTextStyle: (SFHFTableHeaderCellTextStyle) newTextStyle;
- (SFHFTableHeaderCellTextStyle) textStyle;
- (void) setTextAlignment: (SFHFTableHeaderCellTextAlignment) newTextAlignment;
- (SFHFTableHeaderCellTextAlignment) textAlignment;
- (void) setBorderStyle: (SFHFTableHeaderCellBorderStyle) newBorderStyle;
- (SFHFTableHeaderCellBorderStyle) borderStyle;

@end
