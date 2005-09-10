//
//  NSArray+IndexSetAdditions.h
//  Delicious Client
//
//  Written by Scott Stevenson (see http://theocacao.com/document.page/66 for more information)
//

#import <Cocoa/Cocoa.h>


@interface NSArray (IndexSetAddition)
- (NSArray *)subarrayWithIndexes: (NSIndexSet *)indexes;
@end