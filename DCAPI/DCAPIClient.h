//
//  DCAPIClient.h
//  Delicious Client
//
//  Created by Buzz Andersen on Sun Jan 25 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCAPIParser.h"
#import "defines.h"


@interface DCAPIClient : NSObject {
    NSURL *APIURL;
    NSString *username;
    NSString *password;
    id delegate;
}

- initWithAPIURL: (NSURL *) newAPIURL username: (NSString *) newUsername password: (NSString *) newPassword delegate: (id) newDelegate;

/* Note that the username and password are currently not actually used in the HTTP authentication (the credentials have to be present in the keychain when the auth challenge is received).  This is a lame thing necessitated by the way NSURLConnection handles HTTP authentication in synchronous requests, and needs to be fixed. */

- (void) setUsername: (NSString *) newUsername;
- (NSString *) username;
- (void) setPassword: (NSString *) newPassword;
- (NSString *) password;

- (void) setAPIURL: (NSURL *) newAPIURL;
- (NSURL *) APIURL;

- (NSArray *) requestTagsFilteredByDate: (NSDate *) date;
- (NSArray *) requestDatesFilteredByTag: (DCAPITag *) tag;
- (NSArray *) requestPostsFilteredByTag: (DCAPITag *) tag count: (NSNumber *) count;
- (NSArray *) requestPostsForDate: (NSDate *) date tag: (DCAPITag *) tag;
- (void) addPost: (DCAPIPost *) newPost;
- (void) deletePostWithURL: (NSURL *) url;
- (void) renameTag: (NSString *) oldName to: (NSString *) newName;
- (NSData *) sendRequestForURI: (NSURL *) apiURL usingCachePolicy: (NSURLRequestCachePolicy) cachePolicy;

- (void) constructURIString: (NSMutableString **) URIString forFunction: (NSString *) function;

@end
