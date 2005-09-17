//
//  SFHFTableView.h
//  Delicious Client
//
//  Created by Laurence Andersen on Wed Aug 11 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KFTypeSelectTableView.h"


@interface SFHFTableView : KFTypeSelectTableView <NSCoding> {
	NSMutableDictionary *keyActions;
	NSMutableArray *draggingDisabledColumns;
	BOOL lastClickWasInDisabledColumn;
}

- (void) initializeColumnsUsingHeaderCellClass: (Class) cellClass formatterClass: (Class) formatterClass textAlignment: (NSTextAlignment) textAlignment;
- (void) setAction: (SEL) selector forKey: (unichar) key;
- (SEL) actionForKey: (unichar) key;
- (void) setKeyActions: (NSMutableDictionary *) newKeyActions;
- (NSMutableDictionary *) keyActions;
- (NSMutableArray *) draggingDisabledColumns;
- (void) setDraggingDisabledColumns: (NSArray *) newDraggingDisabledColumns;
- (void) enableDraggingForColumnWithIdentifier: (NSString *) identifier;
- (void) disableDraggingForColumnWithIdentifier: (NSString *) identifier;
- (BOOL) draggingIsDisabledForColumnWithIdentifier: (NSString *) identifier;
- (BOOL) lastClickWasInDisabledColumn;

@end

@interface NSObject (SFHFTableViewTooltipDataSource)

// Implement these if you want tooltips.
- (NSString *)tableView:(SFHFTableView *)tableView tooltipForItem:(id)item;
- (id)tableView:(SFHFTableView *)tableView itemAtRow:(int)row;

@end