//
//  AppController.h
//  Delicious Client
//
//  Created by Buzz Andersen on Sun Jan 25 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <openssl/md5.h>
#import "DCAPIClient.h"
#import "DCAPIParser.h"
#import "DCAPITagFormatter.h"
#import "NSString+SFHFUtils.h"
#import "SFHFKeychainUtils.h"
#import "SFHFTableView.h"
#import "SFHFiTunesTableHeaderCell.h"
#import "SFHFMetalTableHeaderCell.h"
#import "SFHFCornerView.h"


@interface AppController : NSObject {
    DCAPIClient *client;
    
    IBOutlet NSProgressIndicator *spinnyThing;
    IBOutlet NSTextField *statusText;
    IBOutlet SFHFTableView *postList;
    IBOutlet SFHFTableView *tagList;
    IBOutlet NSDrawer *metadataDrawer;
    IBOutlet WebView *webView;
    IBOutlet NSTextField *searchField;
    IBOutlet NSMenu *searchMenu;
	
	IBOutlet NSTextField *postDescriptionField;
	IBOutlet NSTextField *postURLField;
	
    IBOutlet NSWindow *mainWindow;
    
    IBOutlet NSPanel *loginPanel;
    IBOutlet NSWindow *postingInterface;
    IBOutlet NSWindow *preferencesWindow;
    
    NSArray *tags;
    NSArray *dates;
    NSArray *posts;
	NSArray *filteredPosts;
    
    NSString *currentSearch;
    DCAPITag *currentTagFilter;

	IBOutlet NSController *loginController;
	NSMutableDictionary *currentPostProperties;
	NSMutableDictionary *loginProperties;

	BOOL useExtendedSearch;
}

- (void) setupTaglist;
- (void) setupPostlist;

- (IBAction) openSelected: (id) sender;
- (IBAction) refresh: (id) sender;
- (void) refreshTags;
- (void) refreshPosts;
- (void) refreshDates;
- (void) refreshAll;

- (void) doSearchForString: (NSString *) string;
- (NSArray *) filterPosts: (NSArray *) postList forSearch: (NSString *) search;

- (void) login;
- (void) loginWithUsername: (NSString *) username password: (NSString *) password APIURL: (NSURL *) APIURL;

- (void) setClient: (DCAPIClient *) newClient;
- (DCAPIClient *) client;
- (void) setTags: (NSArray *) newTags;
- (NSArray *) tags;
- (void) setDates: (NSArray *) newDates;
- (NSArray *) dates;
- (void) setPosts: (NSArray *) newPosts;
- (NSArray *) posts;
- (void) setFilteredPosts: (NSArray *) newFilteredPosts;
- (NSArray *) filteredPosts;
- (void) setCurrentTagFilter: (DCAPITag *) newTagFilter;
- (DCAPITag *) currentTagFilter;
- (void) updateTagFilterFromSelection;
- (void) setCurrentSearch: (NSString *) newCurrentSearch;
- (NSString *) currentSearch;

- (void) resetPostView;

- (IBAction) loginFromPanel: (id) sender;
- (IBAction) cancelLogin: (id) sender;
- (IBAction) openRegistrationURL: (id) sender;
- (IBAction) showPostingInterface: (id) sender;
- (IBAction) closePostingInterface: (id) sender;
- (IBAction) postNewLink: (id) sender;
- (IBAction) editSelectedLinks: (id) sender;
- (IBAction) deleteSelectedLinks: (id) sender;
- (IBAction) setSearchTypeToBasic: (id) sender;
- (IBAction) setSearchTypeToExtended: (id) sender;
- (IBAction) copyAsTag: (id) sender;

@end
