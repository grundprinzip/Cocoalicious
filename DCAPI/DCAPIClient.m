//
//  DCAPIClient.m
//  Delicious Client
//
//  Created by Buzz Andersen on Sun Jan 25 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPIClient.h"
#import "SFHFNetworkUtils.h"


static NSString *kGET_POSTS_RELATIVE_URI = @"/posts/get";
static NSString *kGET_DATES_RELATIVE_URI = @"/posts/dates";
static NSString *kGET_TAGS_RELATIVE_URI = @"/tags/get";
static NSString *kGET_ALL_POSTS_RELATIVE_URI = @"/posts/all";
static NSString *kGET_RECENT_POSTS_RELATIVE_URI = @"/posts/recent";
static NSString *kGET_LAST_UPDATE_TIME_RELATIVE_URI = @"/posts/update";
static NSString *kADD_POST_RELATIVE_URI = @"/posts/add";
static NSString *kDELETE_POST_RELATIVE_URI = @"/posts/delete";
static NSString *kRENAME_TAG_RELATIVE_URI = @"/tags/rename";
static NSString *kDATE_FILTER_PARAM = @"dt";
static NSString *kTAG_FILTER_PARAM = @"tag";
static NSString *kCOUNT_FILTER_PARAM = @"count";
static NSString *kPOST_URL_PARAM = @"url";
static NSString *kPOST_DESCRIPTION_PARAM = @"description";
static NSString *kPOST_TAGS_PARAM = @"tags";
static NSString *kPOST_DATE_PARAM = @"dt";
static NSString *kPOST_EXTENDED_PARAM = @"extended";
static NSString *kRENAME_TAG_OLD_PARAM = @"old";
static NSString *kRENAME_TAG_NEW_PARAM = @"new";
static double kREQUEST_TIMEOUT_INTERVAL = 30.0;
static double kAPI_INTER_REQUEST_DELAY = 1.0;
static NSString *kUSER_AGENT_HTTP_HEADER = @"User-Agent";
static NSString *kLEGAL_CHARACTERS_TO_BE_ESCAPED = @"@?&/;+";

#warning Need better error handling across the board for failed requests (esp. 503s).
#warning Might want to have configurable request timeout.

@implementation DCAPIClient

- initWithAPIURL: (NSURL *) newAPIURL username: (NSString *) newUsername password: (NSString *) newPassword delegate: (id) newDelegate {
    [super init];
    
    delegate = newDelegate;
    
    [self setUsername: newUsername];
    [self setPassword: newPassword];
	
    if (newAPIURL == nil) {
        [self setAPIURL: [NSURL URLWithString: kDEFAULT_API_URL]];
    }
    else {
        [self setAPIURL: newAPIURL];
    }
    
    return self;
}

- (void) setUsername: (NSString *) newUsername {
    if (username != newUsername) {
        [username release];
        username = [newUsername copy];
    }
}

- (NSString *) username {
    return [[username retain] autorelease];
}

- (void) setPassword: (NSString *) newPassword {
    if (password != newPassword) {
        [password release];
        password = [newPassword copy];
    }
}

- (NSString *) password {
    return [[password retain] autorelease];
}

- (void) setAPIURL: (NSURL *) newAPIURL {
    if (APIURL != newAPIURL) {
        [APIURL release];
        APIURL = [newAPIURL copy];
    }
}

- (NSURL *) APIURL {
    return [[APIURL retain] autorelease];
}

- (void) constructURIString: (NSMutableString **) URIString forFunction: (NSString *) function {
    NSString *user = [self username];
    NSString *pass = [self password];

    if (!user || !pass) {
        *URIString = nil;
        return;
    }    
	
    *URIString = [[NSMutableString alloc] init];

	#warning Username and password not actually used in format string (see header for explanation)!  Needs to be fixed!
    [*URIString appendFormat: @"%@%@?", [[self APIURL] absoluteString], function];
    [*URIString autorelease];
}

- (NSArray *) requestTagsFilteredByDate: (NSDate *) date {
    NSMutableString *getTagsURIString;
	NSError *error;
    
    [self constructURIString: &getTagsURIString forFunction: kGET_TAGS_RELATIVE_URI];

    if (!getTagsURIString) {
        return nil;
    }    
    
    if (date) {
        [getTagsURIString appendFormat: @"%@=%@", kDATE_FILTER_PARAM, [date descriptionWithCalendarFormat: kDEFAULT_DATE_FORMAT timeZone: nil locale: nil]];
    }
    
    NSURL *apiURL = [NSURL URLWithString: getTagsURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestReloadIgnoringCacheData response: nil error: &error];

    DCAPIParser *parser = [[DCAPIParser alloc] initWithXMLData: responseData];
    
    NSMutableArray *tags;
    [parser parseForPosts: nil dates: nil tags: &tags];
    [parser release];
    	
    return tags;
}

- (NSArray *) requestDatesFilteredByTag: (DCAPITag *) tag {
    NSMutableString *getDatesURIString;
	NSError *error;
    
    [self constructURIString: &getDatesURIString forFunction: kGET_DATES_RELATIVE_URI];

    if (!getDatesURIString) {
        return nil;
    }
    
    if (tag) {
        [getDatesURIString appendFormat: @"%@=%@", kTAG_FILTER_PARAM, [[tag name] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
    }
    
    NSURL *apiURL = [NSURL URLWithString: getDatesURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestUseProtocolCachePolicy response: nil error: &error];

    DCAPIParser *parser = [[DCAPIParser alloc] initWithXMLData: responseData];
    
    NSMutableArray *dates;
    [parser parseForPosts: nil dates: &dates tags: nil];
    [parser release];
    
	return dates;
}

- (NSArray *) requestPostsFilteredByTag: (DCAPITag *) tag count: (NSNumber *) count {
    NSMutableString *getPostsURIString;
    NSError *error;
	
	if (count || tag) {
		[self constructURIString: &getPostsURIString forFunction: kGET_RECENT_POSTS_RELATIVE_URI];
	}
	else {
		[self constructURIString: &getPostsURIString forFunction: kGET_ALL_POSTS_RELATIVE_URI];
	}

    if (!getPostsURIString) {
        return nil;
    }

	if (count) {
		[getPostsURIString appendFormat: @"%@=%@", kCOUNT_FILTER_PARAM, count];	
	}

    if (tag) {
		#warning This is really ugly--need more intelligent way to add params to URL
		if (count) {
            [getPostsURIString appendString: @"&"];
		}
		else if ([tag count]) {
			[getPostsURIString appendFormat: @"%@=%@",  kCOUNT_FILTER_PARAM, [tag count]];
			[getPostsURIString appendString: @"&"];
		}
	
        [getPostsURIString appendFormat: @"%@=%@", kTAG_FILTER_PARAM, [[tag name] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
    }

    NSURL *apiURL = [NSURL URLWithString: getPostsURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestUseProtocolCachePolicy response: nil error: &error];

    DCAPIParser *parser = [[DCAPIParser alloc] initWithXMLData: responseData];
    
    NSMutableArray *posts;
    [parser parseForPosts: &posts dates: nil tags: nil];
    [parser release];
	
    return posts;
}

- (NSArray *) requestPostsForDate: (NSDate *) date tag: (DCAPITag *) tag {
    NSMutableString *getPostsURIString;
    NSError *error;
	
    [self constructURIString: &getPostsURIString forFunction: kGET_POSTS_RELATIVE_URI];
    
    if (!getPostsURIString) {
        return nil;
    }
    
    if (date) {
        [getPostsURIString appendFormat: @"%@=%@", kDATE_FILTER_PARAM, [date descriptionWithCalendarFormat: kDEFAULT_DATE_FORMAT timeZone: [NSTimeZone timeZoneWithName: kDEFAULT_TIME_ZONE_NAME] locale: nil]];
    }
    
    if (tag) {
        [getPostsURIString appendFormat: @"&%@=%@", kTAG_FILTER_PARAM, [[tag name] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
    }
    
    NSURL *apiURL = [NSURL URLWithString: getPostsURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestUseProtocolCachePolicy response: nil error: &error];

    DCAPIParser *parser = [[DCAPIParser alloc] initWithXMLData: responseData];
    
	NSMutableArray *posts;
    [parser parseForPosts: &posts dates: nil tags: nil];
    [parser release];
   
	 return posts;
}

- (NSDate *) requestLastUpdateTime: (NSError **) error {
    NSMutableString *lastUpdateURIString;
	
    [self constructURIString: &lastUpdateURIString forFunction: kGET_LAST_UPDATE_TIME_RELATIVE_URI];

    if (!lastUpdateURIString) {
        return nil;
    }

    NSURL *apiURL = [NSURL URLWithString: lastUpdateURIString];

    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestReloadIgnoringCacheData response: nil error: error];
	
	DCAPIParser *parser = [[[DCAPIParser alloc] initWithXMLData: responseData] autorelease];
	NSDate *lastUpdateTime = [parser parseForLastUpdateTime];
	
	return lastUpdateTime;
}

- (void) addPost: (DCAPIPost *) newPost {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableString *addPostURIString;
	NSError *error;
    
    [self constructURIString: &addPostURIString forFunction: kADD_POST_RELATIVE_URI];
    
    if (!addPostURIString) {
        return;
    }
	
	NSString *URLString = [[newPost URL] absoluteString];
	
    if (URLString) {
        [addPostURIString appendFormat: @"%@=%@", kPOST_URL_PARAM, [URLString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
    }
	
	NSString *description = [newPost description];
	
	if (description) {
        [addPostURIString appendFormat: @"&%@=%@", kPOST_DESCRIPTION_PARAM, [description stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];	
	}
	
	NSString *extended = [newPost extended];
	
	if (extended) {
        [addPostURIString appendFormat: @"&%@=%@", kPOST_EXTENDED_PARAM, [extended stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
	}
		
	NSString *tags = [newPost tagsAsString];
	
	if (tags) {
        [addPostURIString appendFormat: @"&%@=%@", kPOST_TAGS_PARAM, [tags stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
	}

	NSDate *postDate = [newPost date];

	if (postDate) {
		NSString *dateString = [postDate descriptionWithCalendarFormat: kPOSTING_DATE_TIME_FORMAT timeZone: [NSTimeZone timeZoneWithAbbreviation: kDEFAULT_TIME_ZONE_NAME] locale: nil];
		[addPostURIString appendFormat: @"&%@=%@", kPOST_DATE_PARAM, [dateString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
	}

    NSURL *apiURL = [NSURL URLWithString: addPostURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestReloadIgnoringCacheData response: nil error: &error];

	[pool release];
}

- (void) deletePostWithURL: (NSURL *) url {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error;
	
	NSMutableString *addPostURIString;

	if (!url) {
		return;
	}

    [self constructURIString: &addPostURIString forFunction: kDELETE_POST_RELATIVE_URI];
	
	[addPostURIString appendFormat: @"%@=%@", kPOST_URL_PARAM, [[url absoluteString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
    
    NSURL *apiURL = [NSURL URLWithString: addPostURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestReloadIgnoringCacheData response: nil error: &error];	
	[pool release];
}

- (void) renameTag: (NSDictionary *) renameInfo {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self renameTag: [renameInfo objectForKey: kDCAPITagRenameFromKey] to: [renameInfo objectForKey: kDCAPITagRenameToKey]];
	[pool release];
}

- (void) renameTag: (NSString *) oldName to: (NSString *) newName {
    NSMutableString *renameTagURIString;
	NSError *error;
    
	if (!oldName || !newName) {
		return;
	}
	
    [self constructURIString: &renameTagURIString forFunction: kRENAME_TAG_RELATIVE_URI];

    if (!renameTagURIString) {
        return;
    }
	
	[renameTagURIString appendFormat: @"%@=%@", kRENAME_TAG_OLD_PARAM, [oldName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];
	[renameTagURIString appendFormat: @"&%@=%@", kRENAME_TAG_NEW_PARAM, [newName stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding legalURLCharactersToBeEscaped: kLEGAL_CHARACTERS_TO_BE_ESCAPED]];

    NSURL *apiURL = [NSURL URLWithString: renameTagURIString];
 
    NSData *responseData = [self sendRequestForURI: apiURL usingCachePolicy: NSURLRequestReloadIgnoringCacheData response: nil error: &error];
}

- (NSData *) sendRequestForURI: (NSURL *) apiURL usingCachePolicy: (NSURLRequestCachePolicy) cachePolicy response: (NSURLResponse **) response error: (NSError **) error {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: apiURL cachePolicy: cachePolicy timeoutInterval: kREQUEST_TIMEOUT_INTERVAL];
		
    [req setValue: kUSER_AGENT forHTTPHeaderField: kUSER_AGENT_HTTP_HEADER];
	
	NSDate *now = [NSDate date];
	NSDate *lastSubmission = [self lastAPISubmissionTime];
	
	if (lastSubmission && [now timeIntervalSinceDate: lastSubmission] < kAPI_INTER_REQUEST_DELAY) {
		[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: kAPI_INTER_REQUEST_DELAY]];
	}

	[self setLastAPISubmissionTime: now];
	NSData *returnData = [NSURLConnection sendSynchronousRequest: req returningResponse: response error: error];
		
	if (*error) { 
		NSLog(@"%@", *error);
	}
	
	return returnData;
}

- (void) setLastAPISubmissionTime: (NSDate *) newLastAPISubmissionTime {
	if (newLastAPISubmissionTime != lastAPISubmissionTime) {
		[lastAPISubmissionTime release];
		lastAPISubmissionTime = [newLastAPISubmissionTime copy];
	}
}

- (NSDate *) lastAPISubmissionTime {
	return [[lastAPISubmissionTime retain] autorelease];
}

- (void) dealloc {
    [username release];
    [password release];
    [APIURL release];
	[lastAPISubmissionTime release];
    [super dealloc];
}

@end
