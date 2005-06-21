//
//  EBFavIconUtils.h
//  Delicious Client
//
//  Created by Eric Blair on 6/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EBFavIconUtils : NSObject {

}

+ (NSString *)downloadFavIconForURL:(NSURL *)aURL
	forceDownload:(BOOL)aForceDownload;

@end
