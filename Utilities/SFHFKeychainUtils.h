//
//  SFHFKeychainUtils.h
//  Delicious Client
//
//  Created by Laurence Andersen on Wed Oct 13 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>


@interface SFHFKeychainUtils : NSObject {

}

+ (NSString *) getWebPasswordForUser: (NSString *) username URL: (NSURL *) url domain: (NSString *) domain itemReference: (SecKeychainItemRef *) itemRef;
+ (BOOL) addWebPassword: (NSString *) password forUser: (NSString *) username URL: (NSURL *) url domain: (NSString *) domain;
+ (BOOL) changePasswordForItem: (SecKeychainItemRef) itemRef to: (NSString *) password;

@end
