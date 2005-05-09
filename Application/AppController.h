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
#import "NSDictionary+SFHFUtils.h"
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
	
	IBOutlet NSView *statusView;
	IBOutlet NSView *statusTextView;
	IBOutlet NSView *indexingProgressView;
	IBOutlet NSProgressIndicator *indexingProgressBar;
	IBOutlet NSTextField *indexingStatusText;
    
    NSArray *tags;
    NSMutableDictionary *posts;
	NSArray *filteredPosts;
    
    NSString *currentSearch;
    DCAPITag *currentTagFilter;

	IBOutlet NSController *loginController;
	NSMutableDictionary *currentPostProperties;
	NSMutableDictionary *loginProperties;

	BOOL useExtendedSearch;
	
	BOOL lastTextChangeWasCompletion;
    
	NSAppleScript *safariScript;
	NSMenu *dockMenu;
	
	NSTimer *autocompleteTimer;
	
#ifdef AWOOSTER_CHANGES
    FullTextIndex *textIndex;
    BOOL useFullTextSearch;
#endif
}

/* del.icio.us API interaction */
- (void) setClient: (DCAPIClient *) newClient;
- (DCAPIClient *) client;
- (void) login;
- (void) loginWithUsername: (NSString *) username password: (NSString *) password APIURL: (NSURL *) APIURL;
- (IBAction) refresh: (id) sender;
- (void) refreshAll;
- (void) refreshTags;
- (void) refreshPostsWithDownload: (BOOL) download;

/* Search/Tag Filtering */
- (IBAction) doSearch: (id) sender;
- (void) doSearchForString: (NSString *) string;
- (NSArray *) filterPosts: (NSArray *) postArray forSearch: (NSString *) search tags: (NSArray *) matchTags;
- (void) setCurrentSearch: (NSString *) newCurrentSearch;
- (NSString *) currentSearch;
- (void) setCurrentTagFilter: (DCAPITag *) newTagFilter;
- (DCAPITag *) currentTagFilter;
- (void) updateTagFilterFromSelection;
- (NSArray *) selectedTags;
#ifdef AWOOSTER_CHANGES
- (void) beginFullTextSearchForQuery: (NSString *) query;
- (void)updateIndexing: (id)anObject;
- (IBAction) setSearchTypeToFullText: (id) sender;
- (IBAction) indexAll: (id) sender;
- (IBAction) indexSelected: (id) sender;
#endif

/* Model */
- (void) insertPost: (DCAPIPost *) newPost;
- (void) setPosts: (NSDictionary *) newPosts;
- (void) setPostsWithArray: (NSArray *) newPosts;
- (NSMutableDictionary *) posts;
- (NSArray *) postsArray;
- (NSArray *) urlsArray;
- (void) setFilteredPosts: (NSArray *) newFilteredPosts;
- (NSArray *) filteredPosts;
- (void) setTags: (NSArray *) newTags;
- (NSArray *) tags;

/* UI setup */
- (void) setupTaglist;
- (void) setupPostlist;
- (void) setupToolbar;
- (void) setUpDockMenu;
- (void) sizeBezelSubviews;
- (void) setupWebPreview;

/* UI Actions */
- (IBAction) openSelected: (id) sender;
- (IBAction) openMainWindow: (id) sender;
- (IBAction) loginFromPanel: (id) sender;
- (IBAction) cancelLogin: (id) sender;
- (IBAction) openRegistrationURL: (id) sender;
- (IBAction) addOrDeleteLinks: (id) sender;
- (IBAction) toggleWebPreview: (id) sender;
- (IBAction) toggleStatusViewToIndexing;
- (IBAction) toggleStatusViewToStatusText;
- (IBAction) showPostingInterface: (id) sender;
- (IBAction) closePostingInterface: (id) sender;
- (IBAction) postNewLink: (id) sender;
- (IBAction) postCurrentSafariURL: (id) sender;
- (IBAction) editSelectedLinks: (id) sender;
- (IBAction) deleteSelectedLinks: (id) sender;
- (IBAction) setSearchTypeToBasic: (id) sender;
- (IBAction) setSearchTypeToExtended: (id) sender;
- (IBAction) copyAsTag: (id) sender;

/* Misc. */
- (void) handleScriptError: (NSDictionary *) errorInfo;
- (void) resetPostView;
- (void) previewSelectedLinks;

@end
