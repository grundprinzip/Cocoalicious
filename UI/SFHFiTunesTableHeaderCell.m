//
//  SFHFiTunesTableHeaderCell.m
//  Delicious Client
//
//  Created by Laurence Andersen on Fri Oct 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SFHFiTunesTableHeaderCell.h"


@implementation SFHFiTunesTableHeaderCell

- (id) initTextCell: (NSString *) text {
    if (self = [super initTextCell: text]) {
		[self setBorderStyle: SFHFiTunesTableHeaderCellBorderStyle];
		return self;
	}

	return nil;
}

@end
