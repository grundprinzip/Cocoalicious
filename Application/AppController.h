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
#import "NSAppleScript+HandlerCalls.h"
#import "SFHFKeychainUtils.h"
#import "SFHFTableView.h"
#import "SFHFBezelView.h"
#import "SFHFSplitView.h"
#import "SFHFiTunesTableHeaderCell.h"
#import "SFHFMetalTableHeaderCell.h"
#import "SFHFCornerView.h"
#import "defines.h"
#import "DCTypes.h"

#ifdef AWOOSTER_CHANGES
#import "FullTextIndex.h"
#endif

@interface AppController : NSObject {
    DCAPIClient *client;
    
    IBOutlet NSProgressIndicator *spinnyThing;
    IBOutlet NSTextField *statusText;
    IBOutlet SFHFTableView *postList;
	IBOutlet SFHFBezelView *postListBezel;
    IBOutlet SFHFTableView *tagList;
    IBOutlet NSDrawer *metadataDrawer;
	IBOutlet SFHFBezelView *webViewBezel;
    IBOutlet WebView *webView;
    IBOutlet NSTextField *searchField;
    IBOutlet NSMenu *searchMenu;
	
	NSRect lastPostListBezelFrame;
	
	IBOutlet NSSegmentedControl *refreshButton;
	IBOutlet NSSegmentedControl *addDeletePostButton;
	IBOutlet NSSegmentedControl *showInfoButton;
	IBOutlet NSSegmentedControl *toggleWebPreviewButton;
	
	IBOutlet NSTextField *postDescriptionField;
	IBOutlet NSTextField *postURLField;
	IBOutlet NSTextField *postExtendedField;
	IBOutlet NSTextView *postTagsField;
	
    IBOutlet NSWindow *mainWindow;
    
    IBOutlet NSPanel *loginPanel;
    IBOutlet NSWindow *postingInterface;
    IBOutlet NSWindow *preferencesWindow;
	IBOutlet SFHFSplitView *previewSplitView;
    
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
	
	BOOL lastTextChangeWasCompletion;
    
	NSAppleScript *safariScript;
	
	NSTimer *autocompleteTimer;
	
#ifdef AWOOSTER_CHANGES
    FullTextIndex *textIndex;
    BOOL useFullTextSearch;
#endif
}

- (void) setupTaglist;
- (void) setupPostlist;
- (void) setupToolbar;
- (void) sizeBezelSubviews;
- (void) setupWebPreview;

- (IBAction) openSelected: (id) sender;
- (IBAction) refresh: (id) sender;
- (void) refreshTags;
- (void) refreshPostsWithDownload: (BOOL) download;
- (void) refreshDates;
- (void) refreshAll;

- (IBAction) doSearch: (id) sender;
- (void) doSearchForString: (NSString *) string;
//- (NSArray *) filterPosts: (NSArray *) postArray forTags: (NSArray *) matchTags;
- (NSArray *) filterPosts: (NSArray *) postArray forSearch: (NSString *) search tags: (NSArray *) matchTags;

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

- (NSArray *) selectedTags;

- (void) resetPostView;
- (void) previewSelectedLinks;

- (IBAction) loginFromPanel: (id) sender;
- (IBAction) cancelLogin: (id) sender;
- (IBAction) openRegistrationURL: (id) sender;
- (IBAction) addOrDeleteLinks: (id) sender;
- (IBAction) toggleWebPreview: (id) sender;
- (IBAction) showPostingInterface: (id) sender;
- (IBAction) closePostingInterface: (id) sender;
- (IBAction) postNewLink: (id) sender;
- (IBAction) postCurrentSafariURL: (id) sender;
- (IBAction) editSelectedLinks: (id) sender;
- (IBAction) deleteSelectedLinks: (id) sender;
- (void) handleScriptError: (NSDictionary *) errorInfo;
- (IBAction) setSearchTypeToBasic: (id) sender;
- (IBAction) setSearchTypeToExtended: (id) sender;
#ifdef AWOOSTER_CHANGES
- (void) beginFullTextSearchForQuery: (NSString *) query;
- (void)updateIndexing: (id)anObject;
- (IBAction) setSearchTypeToFullText: (id) sender;
- (IBAction) indexAll: (id) sender;
#endif
- (IBAction) copyAsTag: (id) sender;

@end
