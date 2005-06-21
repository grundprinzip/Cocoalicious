//
//  NSFoundation+ESBExtension.h
//  ESBFoundation
//
//  Created by Eric Blair on Wed Sep 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (ESBExtensions)

// Directory manipulations
- (BOOL)directoryExistsAtPath:(NSString *)path;
- (BOOL)directoryExistsAtPath:(NSString *)path
	traverseLink:(BOOL)traverseLink;

// Creates any directories needed to be able to create a file at the specified
// path.  Raises an exception on failure.
- (void)createPathToFile:(NSString *)path
	attributes:(NSDictionary *)attributes;
- (void)createPath:(NSString *)path
	attributes:(NSDictionary *)attributes;

// Returns the ~/Library/Application Support/<App Display Name> folder,
// creating any necessary folders along the path hierarchy.
- (NSString *)getApplicationSupportFolder;

// Returns a folder path within the 
// ~/Library/Application Support/<App Display Name>/ folder, creating
// the any necessary folders along the path hierarchy.
- (NSString *)getApplicationSupportSubpath:(NSString *)subPath;

@end
