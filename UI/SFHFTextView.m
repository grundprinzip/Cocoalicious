//
//  SFHFTextView.m
//  Delicious Client
//
//  Created by Laurence Andersen on Thu Feb 03 2005.
//  Copyright (c) 2005 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFTextView.h"


@implementation SFHFTextView

- (void) insertCompletion: (NSString *) word forPartialWordRange: (NSRange) charRange movement: (int) movement isFinal: (BOOL) isFinal {
	id delegate = [self delegate];

	if (movement == NSCancelTextMovement && [delegate respondsToSelector:@selector(textViewCancelledCompletion:)]) {
		[delegate textViewCancelledCompletion: self];
	}
	else if (isFinal && [delegate respondsToSelector:@selector(textViewFinishedCompletion:)]) {
		[delegate textViewFinishedCompletion: self];
	}

	[super insertCompletion: word forPartialWordRange: charRange movement: movement isFinal: isFinal];
}

@end
