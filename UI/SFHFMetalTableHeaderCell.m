//
//  SFHFMetalTableHeaderCell.m
//  Delicious Client
//
//  Created by Laurence Andersen on Fri Oct 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SFHFMetalTableHeaderCell.h"


@implementation SFHFMetalTableHeaderCell

- (id) initTextCell: (NSString *) text {
    if (self = [super initTextCell: text]) {
		[self setBackgroundTexture: [NSImage imageNamed: @"metal_column_header.png"]];
		[self setBorderStyle: SFHFiTunesTableHeaderCellBorderStyle];
		[self setTextStyle: SFHFEmbossedTableHeaderCellTextStyle];
		[self setTextAlignment: SFHFCenteredTableHeaderCellTextAlignment];
    
		return self;
	}
	
	return nil;
}

@end
