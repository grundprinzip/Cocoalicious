//
//  SFHFTableView.m
//  Delicious Client
//
//  Created by Laurence Andersen on Wed Aug 11 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFTableView.h"


@implementation SFHFTableView

- init {
    [super init];
    [self setKeyActions: [NSMutableDictionary dictionary]];
    return self;
}

- (id) initWithCoder: (NSCoder *) decoder {
    self = [super initWithCoder: decoder];
	NSMutableDictionary *actions = [decoder decodeObjectForKey: @"keyActions"];
	
	if (actions) {
		[self setKeyActions: actions];
	}
	else {
		[self setKeyActions: [NSMutableDictionary dictionaryWithCapacity: 1]];		
	}
	
    return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder {
    [super encodeWithCoder: encoder];
    [encoder encodeObject: [self keyActions] forKey: @"keyActions"];	
}

- (void) textDidEndEditing: (NSNotification *) aNotification {
	int movement = [[[aNotification userInfo] objectForKey: @"NSTextMovement"] intValue];
	BOOL doEdit = YES;
	
	[super textDidEndEditing: aNotification];

	// was the movement a return?
	if (movement == NSReturnTextMovement) {
		doEdit = NO;
	}
	else if (movement == NSReturnTextMovement) {
		doEdit = YES;
	}
	else if (movement == NSTabTextMovement) {
		doEdit = YES;
	}

	if (!doEdit) {
		[self validateEditing];
		[self abortEditing];
		[[self window] makeFirstResponder: self];
	}
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal {
    if (isLocal) {
		return NSDragOperationEvery;
	}
	else {
   		return NSDragOperationCopy;
	}
}

- (void) keyDown: (NSEvent *) theEvent {
	unichar c = [[theEvent characters] characterAtIndex: 0];
	
	SEL keyAction = [self actionForKey: c];
	
	if (keyAction) {
		[self sendAction: keyAction to: [self target]];
	}
	else {
		[super keyDown: theEvent];
	}
}

- (void) copy: (id) sender {
	NSIndexSet *rows = [self selectedRowIndexes];

	NSMutableArray *rowsToCopy = [NSMutableArray array];

    unsigned int currentIndex = [rows firstIndex];
    
	while (currentIndex != NSNotFound) {
		[rowsToCopy addObject: [NSNumber numberWithUnsignedInt: currentIndex]];
        currentIndex = [rows indexGreaterThanIndex: currentIndex];
	}

	[[self delegate] tableView: self writeRows: rowsToCopy toPasteboard: [NSPasteboard generalPasteboard]];
}

- (void) initializeColumnsUsingHeaderCellClass: (Class) cellClass formatterClass: (Class) formatterClass {
    NSArray *columns = [self tableColumns];
    NSEnumerator *cols = [columns objectEnumerator];
    NSTableColumn *col = nil;
	
    id formatter = [[formatterClass alloc] init];
	
    while (col = [cols nextObject]) {
		id headerCell = [[cellClass alloc] initTextCell: [[col headerCell] stringValue]];
        [col setHeaderCell: headerCell];
        [headerCell release];

		if (formatter) {
			NSCell *dataCell = [col dataCell];
			[dataCell setFormatter: formatter];
		}
	}
	
	[formatter release];
}

- (void)buildTooltips; {
    NSRange range;
    unsigned int index;
    
    if (![_dataSource respondsToSelector:@selector(tableView:tooltipForItem:)])
        return;
    
    [self removeAllToolTips];
    range = [self rowsInRect:[self visibleRect]];
    for (index = range.location; index < NSMaxRange(range); index++) {
        NSString *tooltip;
        id item;
        
        item = [_dataSource tableView:self itemAtRow:index];
        tooltip = [_dataSource tableView:self tooltipForItem:item];
        if (tooltip)
            [self addToolTipRect:[self rectOfRow:index] owner:self userData:NULL];
    }
}

- (NSString *)view:(NSView *)view 
  stringForToolTip:(NSToolTipTag)tag 
             point:(NSPoint)point 
          userData:(void *)data; {
    int row;
    
    row = [self rowAtPoint:point];
    return [_dataSource tableView:self tooltipForItem:[_dataSource tableView:self itemAtRow:row]];
}

- (void)resetCursorRects; {
    [self buildTooltips];
}

- (void) setAction: (SEL) selector forKey: (unichar) key {
	NSMutableDictionary *actions = [self keyActions];
	
	if (actions) {
		[actions setValue: NSStringFromSelector(selector) forKey: [NSString stringWithCharacters: &key length: 1]];
	}
}

- (SEL) actionForKey: (unichar) key {
	NSMutableDictionary *actions = [self keyActions];
	
	if (actions) {
		NSString *keyActionValue = [actions objectForKey: [NSString stringWithCharacters: &key length: 1]];
	
		if (keyActionValue) {
			SEL keyAction = NSSelectorFromString(keyActionValue);
			return keyAction;
		}
	}
	
	return nil;
}

- (void) setKeyActions: (NSMutableDictionary *) newKeyActions {
	if (keyActions != newKeyActions) {
		[newKeyActions retain];
		[keyActions release];
		keyActions = newKeyActions;
	}
}

- (NSMutableDictionary *) keyActions {
	return [[keyActions retain] autorelease];
}

- (void) dealloc {
	[keyActions release];
	[super dealloc];
}

@end

