//
//  SFHFTableView.h
//  Delicious Client
//
//  Created by Laurence Andersen on Wed Aug 11 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SFHFTableView : NSTableView <NSCoding> {
	NSMutableDictionary *keyActions;
}

- (void) initializeColumnsUsingHeaderCellClass: (Class) cellClass formatterClass: (Class) formatterClass;
- (void) setAction: (SEL) selector forKey: (unichar) key;
- (SEL) actionForKey: (unichar) key;
- (void) setKeyActions: (NSMutableDictionary *) newKeyActions;
- (NSMutableDictionary *) keyActions;

@end
