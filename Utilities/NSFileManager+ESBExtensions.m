//
//  NSFoundation+ESBExtension.m
//  ESBFoundation
//
//  Created by Eric Blair on Wed Sep 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+ESBExtensions.h"


@implementation NSFileManager (ESBExtensions)

- (BOOL)directoryExistsAtPath:(NSString *)path
{
	return [self directoryExistsAtPath:path traverseLink:NO];
}

- (BOOL)directoryExistsAtPath:(NSString *)path
	traverseLink:(BOOL)traverseLink
{
    NSDictionary * attributes;

    attributes = [self fileAttributesAtPath:path traverseLink:traverseLink];

    return [[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory];
}

- (void)createPathToFile:(NSString *)path
	attributes:(NSDictionary *)attributes
{
    NSArray * pathComponents;
    unsigned int dirCount;
    NSString * finalDirectory;

    pathComponents = [path pathComponents];
    dirCount = [pathComponents count] - 1;

    // Short-circuit if the final directory already exists
    finalDirectory =
    	[NSString pathWithComponents:
    		[pathComponents subarrayWithRange:NSMakeRange(0, dirCount)]];
    [self createPath:finalDirectory attributes:attributes];
}

- (void)createPath:(NSString *)path
	attributes:(NSDictionary *)attributes
{
    NSArray * pathComponents;
    unsigned int dirIndex, dirCount;
    unsigned int startingIndex;

    pathComponents = [path pathComponents];
    dirCount = [pathComponents count];
    // Short-circuit if the final directory already exists
    path =
    	[NSString pathWithComponents:
    		[pathComponents subarrayWithRange:NSMakeRange(0, dirCount)]];

    if ([self directoryExistsAtPath:path traverseLink:YES])
        return;

    startingIndex = 0;
    
    for (dirIndex = startingIndex; dirIndex < dirCount; dirIndex++) {
        NSString *partialPath;
        BOOL fileExists;

        partialPath =
        	[NSString pathWithComponents:
        		[pathComponents subarrayWithRange:NSMakeRange(0, dirIndex + 1)]];

        // Don't use the 'fileExistsAtPath:isDirectory:' version since it doesn't traverse symlinks
        fileExists = [self fileExistsAtPath:partialPath];
        if (!fileExists) {
            if (![self createDirectoryAtPath:partialPath attributes:attributes])
                [NSException raise:NSGenericException
                	format:@"Unable to create a directory at path: %@", partialPath];
        } else {
            NSDictionary *attributes;

            attributes = [self fileAttributesAtPath:partialPath traverseLink:YES];
            if (![[attributes objectForKey:NSFileType] isEqualToString: NSFileTypeDirectory]) {
                [NSException raise:NSGenericException
                	format:@"Unable to write to path \"%@\" because \"%@\" is not a directory",
                    path, partialPath];
            }
        }
    }
}

- (NSString *)getApplicationSupportFolder
{
	NSArray * domains = 
		NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
											NSUserDomainMask,
											YES);
	NSString * baseDir = [domains objectAtIndex:0];
	NSString * allSupportDir =
		[baseDir stringByAppendingPathComponent:@"Application Support"];
	NSString * appSupportDir =
		[allSupportDir stringByAppendingPathComponent:
			[self displayNameAtPath:[[NSBundle mainBundle] bundlePath]]];
	
	[self createPath:appSupportDir attributes:nil];
	
	return [[appSupportDir copy] autorelease];
}

- (NSString *)getApplicationSupportSubpath:(NSString *)subPath
{
	NSString * appSupportDir = [self getApplicationSupportFolder];
	NSString * appSupportSubdir =
		[appSupportDir stringByAppendingPathComponent:subPath];
	
	[self createPath:appSupportSubdir attributes:nil];
	
	return [[appSupportSubdir copy] autorelease];
}

@end
