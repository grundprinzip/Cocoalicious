//
//  SFHFKeychainUtils.m
//  Delicious Client
//
//  Created by Laurence Andersen on Wed Oct 13 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "SFHFKeychainUtils.h"


@implementation SFHFKeychainUtils

+ (NSString *) getWebPasswordForUser: (NSString *) username URL: (NSURL *) url domain: (NSString *) domain itemReference: (SecKeychainItemRef *) itemRef {
	const char *host = [[url host] UTF8String];
	//const char *path = [[url path] UTF8String];
	const char *user = [username UTF8String];
	const char *dom = [domain UTF8String];
	//UInt16 port = [[url port] shortValue];
	void *password = NULL;
	UInt32 passwordLength = 0;
	
	OSStatus findResult = SecKeychainFindInternetPassword (
		NULL, // default keychain
		strlen(host), // server name length
		host, // server name
		strlen(dom), // security domain length
		dom, // security domain
		strlen(user), // account name length
		user, // account name
		0, // path length
		NULL, // path
		0, // port
		kSecProtocolTypeHTTP, // protocol
		kSecAuthenticationTypeDefault, // authentication type
		&passwordLength, // password length
		&password, // password
		itemRef // item ref
    );

	if (findResult == noErr) {
		NSString *returnString = [NSString stringWithCString: password length: passwordLength];
		SecKeychainItemFreeContent(NULL, password);
		return returnString;
	}

	return nil;
}

+ (BOOL) addWebPassword: (NSString *) password forUser: (NSString *) username URL: (NSURL *) url domain: (NSString *) domain {
	const char *host = [[url host] UTF8String];
	//const char *path = [[url path] UTF8String];
	const char *user = [username UTF8String];
	const char *pass = [password UTF8String];
	const char *dom = [domain UTF8String];
	UInt16 port = [[url port] shortValue];
	SecKeychainItemRef itemRef;
	
	NSString *currentPassword = [SFHFKeychainUtils getWebPasswordForUser: username URL: url domain: domain itemReference: &itemRef];
	
	if (currentPassword) {
		if ([currentPassword isEqualToString: password]) {
			return YES;
		}
	
		return [self changePasswordForItem: itemRef to: password];
	}
	
	OSStatus addResult = SecKeychainAddInternetPassword (
		NULL, // default keychain
		strlen(host), // server name length
		host, // server name
		strlen(dom), // security domain length
		dom, // security domain
		strlen(user), // account name length
		user, // account name
		0, // path length
		NULL, // path
		port, // port
		kSecProtocolTypeHTTP, // protocol
		kSecAuthenticationTypeDefault, // authentication type
		strlen(pass), // password length
		pass, // password
		NULL // item ref
    );
	
	if (addResult == noErr) {
		return YES;
	}
	
	return NO;
}

+ (BOOL) changePasswordForItem: (SecKeychainItemRef) itemRef to: (NSString *) password {
	if (!password || !itemRef) {
		return NO;
	}
	
	const char *pass = [password UTF8String];
	
	NSLog(@"changing password");
	
	OSErr status = SecKeychainItemModifyAttributesAndData (
		itemRef, // the item reference
		NULL, // no change to attributes
		strlen(pass), // length of password
		pass // pointer to password data
    );
	
	if (status == noErr) {
		return YES;
	}
	
	return NO;
}

@end
