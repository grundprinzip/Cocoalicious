//
//  SFHFTextView.h
//  Delicious Client
//
//  Created by Laurence Andersen on Thu Feb 03 2005.
//  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SFHFTextView : NSTextView {

}

- (void) insertCompletion: (NSString *) word forPartialWordRange: (NSRange) charRange movement: (int) movement isFinal: (BOOL) flag;

@end

@interface NSObject (SFHFTextViewDelegate)

- (void) textViewFinishedCompletion: (NSTextView *) textView;
- (void) textViewCancelledCompletion: (NSTextView *) textView;

@end