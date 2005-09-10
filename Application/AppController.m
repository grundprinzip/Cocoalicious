//
//  AppController.m
//  Delicious Client
//
//  Created by Buzz Andersen on Sun Jan 25 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "AppController.h"


const AEKeyword DCNNWPostAppleEventClass = 'EBlg';
const AEKeyword DCNNWPostAppleEventID = 'oitm';
const AEKeyword DCNNWPostTitle = 'titl';
const AEKeyword DCNNWPostDescription = 'desc';
const AEKeyword DCNNWPostSummary = 'summ';
const AEKeyword DCNNWPostLink = 'link';
const AEKeyword DCNNWPostPermalink = 'plnk';
const AEKeyword DCNNWPostSubject = 'subj';
const AEKeyword DCNNWPostCreator = 'crtr';
const AEKeyword DCNNWPostCommentsURL = 'curl';
const AEKeyword DCNNWPostGUID = 'guid';
const AEKeyword DCNNWPostSourceName = 'snam';
const AEKeyword DCNNWPostSourceHomeURL = 'hurl';
const AEKeyword DCNNWPostSourceFeedURL = 'furl';

static NSString *ERR_LOGIN_AUTHENTICATION = @"Invalid Username/Password";
static NSString *ERR_LOGIN_OTHER = @"Login Error.";

@implementation AppController

+ (void) initialize {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: kDEFAULT_API_URL forKey: kAPI_URL_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: kOPEN_URLS_IN_BACKGROUND_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithFloat: 1.0] forKey: kDEACTIVATE_ALPHA_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithBool: YES] forKey: kSHOW_WEB_PREVIEW_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithInt: DCBasicSearchType] forKey: kSEARCH_TYPE_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: kAUTOMATICALLY_COMPLETE_TAGS_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithFloat: kDEFAULT_TAG_AUTOCOMPLETION_DELAY] forKey: kTAG_AUTOCOMPLETION_DELAY_DEFAULTS_KEY];
	
	NSArray *descriptors = [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: kDATE_SORT_DESCRIPTOR ascending: NO] autorelease]];
	NSData *descriptorData = [NSArchiver archivedDataWithRootObject: descriptors];
	
	[dictionary setObject: descriptorData forKey: kPOST_LIST_SORT_DEFAULTS_KEY];
	
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: dictionary];
}

- (id) init {
	if (self = [super init]) {
		currentPostProperties = [[NSMutableDictionary alloc] init];
		loginProperties = [[NSMutableDictionary alloc] init];
#ifdef AWOOSTER_CHANGES
        textIndex = [[FullTextIndex alloc] init];
#endif
	}     
	
	return self;
}

- (void) awakeFromNib {
	[postTagsField setFieldEditor: YES];
	[statusView addSubview: statusTextView];
	[self sizeBezelSubviews];
	[self setupToolbar];
	[self setupWebPreview];
	[self setUpDockMenu];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	/* Support for NetNewsWire External Weblog Editor Interface */
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler: self andSelector: @selector(postNewNNWLink:withReplyEvent:) forEventClass: DCNNWPostAppleEventClass andEventID: DCNNWPostAppleEventID];
	
	[NSApp setServicesProvider: self];
	
	NSError *historyLoadError;
	WebHistory *sharedHistory = [[WebHistory alloc] init];
	[sharedHistory loadFromURL: [NSURL fileURLWithPath: [kSAFARI_HISTORY_PATH stringByExpandingTildeInPath]] error: &historyLoadError];
	
	if (historyLoadError) {
		NSLog(@"%@", historyLoadError);
	}
	else {
		[WebHistory setOptionalSharedHistory: [sharedHistory autorelease]];
	}
				
	NSString *safariScriptPath = [[NSBundle mainBundle] pathForResource: kDCSafariScriptLibrary ofType: kDCScriptType];
	NSURL *safariScriptURL = [NSURL fileURLWithPath: safariScriptPath];
	NSDictionary *errorInfo = nil;
	
	safariScript = [[NSAppleScript alloc] initWithContentsOfURL: safariScriptURL error: &errorInfo];
	
	if (!safariScript || errorInfo) {
        [self handleScriptError: errorInfo];
    }
	
	[postList setDoubleAction: @selector(openSelected:)];
    
    [self setPosts: [NSMutableDictionary dictionaryWithCapacity: 0]];
    [self setTags: [NSMutableDictionary dictionaryWithCapacity: 0]];
	
    [self setupTaglist];
	[self setupPostlist];

	DCSearchType defaultSearchType = [(NSNumber *) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kSEARCH_TYPE_DEFAULTS_KEY] intValue];
	
	switch (defaultSearchType) {
		case DCExtendedSearchType:
			[self setSearchTypeToExtended: self];
			break;
#ifdef AWOOSTER_CHANGES
		case DCFullTextSearchType:
			[self setSearchTypeToFullText: self];
			break;
#endif
		default:
			[self setSearchTypeToBasic: self];
			break;
	}
    
    [[NSUserDefaultsController sharedUserDefaultsController] setAppliesImmediately: YES];
	
	[self login];
}

- (void) setupTaglist {
	[tagList setAction: @selector(makePostListFirstResponder) forKey: NSRightArrowFunctionKey];
	[tagList setAction: @selector(endTagListEditing) forKey: 27];

	[tagList initializeColumnsUsingHeaderCellClass: [SFHFMetalTableHeaderCell class] formatterClass: [DCAPITagFormatter class]];
	
	[tagList registerForDraggedTypes: [NSArray arrayWithObject: kDCAPIPostPboardType]];

    SFHFMetalTableHeaderCell *cornerCell = [[SFHFMetalTableHeaderCell alloc] initTextCell: @" "];
	SFHFCornerView *cornerControl = [[SFHFCornerView alloc] init];
    [cornerControl setCell: cornerCell];
    [tagList setCornerView: cornerControl];
    [cornerControl release];
	[cornerCell release];

	/*SFHFCircularCounterCell *counterCell = [[SFHFCircularCounterCell alloc] init];
	[[tagList tableColumnWithIdentifier: kTAGLIST_TAG_COLUMN_IDENTIFIER] setDataCell: counterCell];
	[counterCell release];*/
}

- (void) setupToolbar {
	[refreshButton setSegmentCount: 1];
	[refreshButton setWidth: 22 forSegment: 0];
	NSImage *refreshIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kREFRESH_BUTTON_IMAGE ofType: @"tif"]];
	[[refreshButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[refreshButton setImage: refreshIcon forSegment: 0];
	[refreshIcon release];
	
	[addDeletePostButton setSegmentCount: 1];
	[addDeletePostButton setWidth: 22 forSegment: 0];
	/*[addDeletePostButton setWidth: 22 forSegment: 1]; */
	NSImage *addPostIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kADD_POST_BUTTON_IMAGE ofType: @"tif"]];
	/* NSImage *deletePostIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kDELETE_POST_BUTTON_IMAGE ofType: @"tif"]]; */
	[[addDeletePostButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[addDeletePostButton setImage: addPostIcon forSegment: 0];
	/* [addDeletePostButton setImage: deletePostIcon forSegment: 1]; */
	[[addDeletePostButton cell] setTag: kADD_POST_SEGMENT_TAG forSegment: 0];
	/* [[addDeletePostButton cell] setTag: kDELETE_POST_SEGMENT_TAG forSegment: 1]; */
	[addPostIcon release];
	/* [deletePostIcon release]; */
		
	[showInfoButton setSegmentCount: 1];
	[showInfoButton setWidth: 22 forSegment: 0];
	NSImage *showInfoIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kSHOW_INFO_BUTTON_IMAGE ofType: @"tif"]];
	[[showInfoButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[showInfoButton setImage: showInfoIcon forSegment: 0];
	[showInfoIcon release];
	
	[toggleWebPreviewButton setSegmentCount: 1];
	[toggleWebPreviewButton setWidth: 22 forSegment: 0];
	NSImage *toggleWebPreviewIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kTOGGLE_WEB_PREVIEW_BUTTON_IMAGE ofType: @"tif"]];
	[[toggleWebPreviewButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[toggleWebPreviewButton setImage: toggleWebPreviewIcon forSegment: 0];
	[toggleWebPreviewIcon release];
}

- (void) setUpDockMenu {
    [NSApp setDelegate: self];
	dockMenu = [[NSMenu alloc] init];
	NSMenuItem *newPostMenuItem = [dockMenu addItemWithTitle: @"New Post" action: @selector(showPostingInterface:) keyEquivalent: @""];
	NSMenuItem *safariNewPostMenuItem = [dockMenu addItemWithTitle: @"New Post from Safari" action: @selector(postCurrentSafariURL:) keyEquivalent: @""];
	[safariNewPostMenuItem setTarget: self];
	[newPostMenuItem setTarget: self];
}

- (NSMenu *) applicationDockMenu: (NSApplication *) sender {
    return dockMenu;
}

- (void) setupPostlist {
	[postList setAction: @selector(openSelected:) forKey: NSRightArrowFunctionKey];
	[postList setAction: @selector(makeTagListFirstResponder) forKey: NSLeftArrowFunctionKey];
	[postList setAction: @selector(scrollWebViewDown) forKey: ' '];
	[postList setAction: @selector(deleteSelectedLinks:) forKey: NSDeleteCharacter];

	NSArray *descriptors = nil;
	NSData *descriptorData = (NSData *) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kPOST_LIST_SORT_DEFAULTS_KEY];
		
	if (descriptorData) {
		descriptors = (NSArray *) [NSUnarchiver unarchiveObjectWithData: descriptorData];
		[postList setSortDescriptors: descriptors];
	}
	
	[postList disableDraggingForColumnWithIdentifier: kRATING_COLUMN_IDENTIFIER];
	
	[postList initializeColumnsUsingHeaderCellClass: [SFHFiTunesTableHeaderCell class] formatterClass: nil];

    SFHFTableHeaderCell *cornerCell = [[SFHFiTunesTableHeaderCell alloc] initTextCell: @" "];
	SFHFCornerView *cornerView = [[SFHFCornerView alloc] init];
    [cornerView setCell: cornerCell];
    [postList setCornerView: cornerView];
    [cornerView release];
	[cornerCell release];
	
	SFHFRatingCell *starCell = [[SFHFRatingCell alloc] initImageCell: [NSImage imageNamed: kRATING_IMAGE_NAME]];
	[starCell setContinuous: YES];
	[starCell setHighlightedImage: [NSImage imageNamed: kRATING_HIGHLIGHTED_IMAGE_NAME]];
	[starCell setMaximumRating: [NSNumber numberWithInt: kMAXIMUM_STAR_RATING]];
	[[postList tableColumnWithIdentifier: kRATING_COLUMN_IDENTIFIER] setDataCell: starCell];
	[starCell release];

#ifdef FAVICON_SUPPORT
	NSTableColumn *descriptionColumn = [postList tableColumnWithIdentifier: @"description"];
	EBIconAndTextCell * descriptionColumnCell = [[EBIconAndTextCell alloc] initWithDefaultIcon: [NSImage imageNamed: @"default_favicon.tif"]];
	[descriptionColumnCell setIconSize: kFAVICON_DISPLAY_SIZE];
	[descriptionColumnCell setFont: [[descriptionColumn dataCell] font]];	// Works, but there must be a better way to set default font
	[descriptionColumn setDataCell: descriptionColumnCell];
	[descriptionColumnCell release];
	[descriptionColumnCell setWraps: YES];
#endif

	NSTableColumn *dateColumn = [postList tableColumnWithIdentifier: @"date"];
	NSCell *dateColumnCell = [dateColumn dataCell];
	[dateColumnCell setWraps: YES];
	NSString *dateFormatString = [[NSUserDefaults standardUserDefaults] stringForKey: NSDateFormatString];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat: dateFormatString allowNaturalLanguage: YES];
	
	[dateColumnCell setFormatter: dateFormatter];
}

- (void) sizeBezelSubviews {
	NSRect webViewBezelFrame = [webViewBezel frame];
	NSRect postListBezelFrame = [[[postList enclosingScrollView] superview] frame];
	NSRect tagListBezelFrame = [[[tagList enclosingScrollView] superview] frame];

	[webView setFrame: NSMakeRect(webViewBezelFrame.origin.x + 2, webViewBezelFrame.origin.y - (postListBezelFrame.size.height + ([previewSplitView dividerThickness] - 2)), webViewBezelFrame.size.width - 4, webViewBezelFrame.size.height - 4)];
	
	[[postList enclosingScrollView] setFrame: NSMakeRect(postListBezelFrame.origin.x + 2, postListBezelFrame.origin.y + 2, postListBezelFrame.size.width - 4, postListBezelFrame.size.height - 3)];
        
	[[tagList enclosingScrollView] setFrame: NSMakeRect(tagListBezelFrame.origin.x + 2, tagListBezelFrame.origin.y + 2, tagListBezelFrame.size.width - 4, tagListBezelFrame.size.height - 3)];

}

- (void) setupWebPreview {
	BOOL displayPreview = [(NSNumber *) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kSHOW_WEB_PREVIEW_DEFAULTS_KEY] boolValue];
	
	if (!displayPreview) {
		[self toggleWebPreview: self];
	}
}

- (IBAction) refresh: (id) sender {
    [NSThread detachNewThreadSelector: @selector(refreshAll) toTarget: self withObject: nil];
}

- (void) refreshAll {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[spinnyThing startAnimation: self];
    [self refreshPostsWithDownload: YES];
	[self refreshTags];
	[spinnyThing stopAnimation: self];
	
	[pool release];
}

- (void) refreshTags {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSMutableDictionary *newTags = [[NSMutableDictionary alloc] init];

	NSEnumerator *postEnum = [[self postsArray] objectEnumerator];
	DCAPIPost *currentPost;
		
	while ((currentPost = (DCAPIPost *) [postEnum nextObject]) != nil) {
		NSEnumerator *postTags = [[currentPost tags] objectEnumerator];
		NSString *currentTagString;
		
		while ((currentTagString = [postTags nextObject]) != nil) {
			DCAPITag *currentTag = [newTags objectForKey: currentTagString];
			
			if (currentTag) {
				[currentTag incrementCount];
			}
			else {
				[newTags setObject: [[DCAPITag alloc] initWithName: currentTagString count: [NSNumber numberWithInt: 1]] forKey: currentTagString];
			}
		}
	}
	
	[self setTags: [newTags autorelease]];
	[self resortTags];
	
	[pool release];
}

- (void) refreshPostsWithDownload: (BOOL) download {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *unfilteredPosts;

	if (download || ![self postsArray]) {
		unfilteredPosts = [[self client] requestPostsFilteredByTag: nil count: nil];
		[self setPostsWithArray: unfilteredPosts];
	}
	else {
		unfilteredPosts = [self postsArray];
	}

	NSArray *resortedPosts = [unfilteredPosts sortedArrayUsingDescriptors: [postList sortDescriptors]];
	
	NSString *search = [self currentSearch];
	NSArray *matchTags = nil;
	
	if (![tagList isRowSelected: 0]) {
		matchTags = [self selectedTags];
	}
	
	if (search || matchTags) {
		[self setFilteredPosts: [self filterPosts: resortedPosts forSearch: search tags: matchTags]];
	}
	else {
		[self setFilteredPosts: resortedPosts];
	}
	
	[postList performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO];
	
	[pool release];
}

- (NSArray *) selectedTags {
	if ([tagList isRowSelected: 0]) {
		return nil;
	}
	
	NSIndexSet *selectedRows = [tagList selectedRowIndexes];
	unsigned currentIndex = [selectedRows firstIndex];
	NSMutableArray *selectedTags = [NSMutableArray array];
	
	while (currentIndex != NSNotFound) {
		[selectedTags addObject: [[[self filteredTags] objectAtIndex: currentIndex - 1] name]];
		currentIndex = [selectedRows indexGreaterThanIndex: currentIndex];
	}
	
	return selectedTags;
}

#ifdef AWOOSTER_CHANGES
- (void)updateIndexing: (id)anObject
{
    if (AWOOSTER_DEBUG)
        NSLog(@"updateIndex:");
    
    /*if ([textIndex indexing] || [textIndex searching]) {
        [spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    } else {
        [spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    }*/
}

- (void) filterPostsForFullTextSearchResult: (NSMutableArray *) results
{
    if (AWOOSTER_DEBUG) {
        NSLog(@"filterPostsForFullTextSearchResult:");
    }
	
	NSEnumerator *resultEnum = [results objectEnumerator];
	NSString *currentURL;
	NSMutableArray *postResults = [[NSMutableArray alloc] init];
	NSDictionary *postsDictionary = [self posts];
	
	while ((currentURL = [resultEnum nextObject]) != nil) {
		DCAPIPost *currentPost = (DCAPIPost *) [postsDictionary objectForKey: currentURL];
			
		if (currentPost) {
			[postResults addObject: currentPost];
		}
	}
	
	NSArray *selectedTags = [self selectedTags];

	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO selector: @selector(compare:)] autorelease];
	NSArray *resortedPosts = [postResults sortedArrayUsingDescriptors: [NSArray arrayWithObjects: sortDescriptor, nil]];
	
	if (selectedTags) {
		[self setFilteredPosts: [self filterPosts: resortedPosts forSearch: nil tags: selectedTags]];
	}
	else {
		[self setFilteredPosts: resortedPosts];
	}
    
    if ([textIndex indexing] || [textIndex searching]) {
        [spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    } else {
        [spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    }
    
	[postList reloadData];
	[postResults release];
}
#endif

- (NSArray *) filterPosts: (NSArray *) postArray forSearch: (NSString *) search tags: (NSArray *) matchTags {
	NSEnumerator *postEnum = [postArray objectEnumerator];
    NSMutableArray *filteredPostList = [[NSMutableArray alloc] init];
	BOOL searchTags = NO;
	BOOL searchURIs = NO;
    
	if (useExtendedSearch) {
		searchTags = YES;
		searchURIs = YES;
	}

    DCAPIPost *currentPost;

    while ((currentPost = [postEnum nextObject]) != nil) {
		if ([currentPost matchesSearch: search extended: YES tags: matchTags matchKeywordsAsTags: searchTags URIs: searchURIs]) {
			[filteredPostList addObject: currentPost];
        }
    }

    return [filteredPostList autorelease];
}

- (void) setClient: (DCAPIClient *) newClient {
    if (client != newClient) {
        [newClient retain];
        [client release];
        client = newClient;
    }
}

- (DCAPIClient *) client {
    return [[client retain] autorelease];
}

- (void) setTags: (NSDictionary *) newTags {
    @synchronized(tags) { 
		if (tags != newTags) {
			[tags release];
			tags = [newTags mutableCopy];
		}
	}
}

- (NSMutableDictionary *) tags {
    return [[tags retain] autorelease];
}

- (void) setFilteredTags: (NSArray *) newFilteredTags {
    @synchronized(filteredTags) { 
		if (filteredTags != newFilteredTags) {
			[filteredTags release];
			filteredTags = [newFilteredTags copy];
		}
	}
}

- (NSArray *) filteredTags {
	return [[filteredTags retain] autorelease];
}

- (NSArray *) tagsArray {
	return [[self tags] allValues];
}

- (void) resortTags {
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];
	NSArray *resortedTags = [[self tagsArray] sortedArrayUsingDescriptors: [NSArray arrayWithObjects: sortDescriptor, nil]];
	[sortDescriptor release];
	[self setFilteredTags: resortedTags];
	//[self updateTagFilterFromSelection];
	[tagList performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO];
}

- (void) renameTag: (NSString *) originalName to: (NSString *) newName withUpload: (BOOL) upload {
	NSEnumerator *postEnum = [[self postsArray] objectEnumerator];
	DCAPIPost *currentPost;
	
	while ((currentPost = (DCAPIPost *) [postEnum nextObject]) != nil) {
		[currentPost renameTag: originalName to: newName];
	}

	if (upload) {
		// UPLOAD TAG RENAME HERE
		NSDictionary *renameDict = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: originalName, newName, nil] forKeys: [NSArray arrayWithObjects: kDCAPITagRenameFromKey, kDCAPITagRenameToKey, nil]];
		[NSThread detachNewThreadSelector: @selector(renameTag:) toTarget: [self client] withObject: renameDict];
	}
	
	[self refreshTags];
	[postList reloadData];
}

- (void) setPostsWithArray: (NSArray *) newPosts {
	@synchronized(posts) { 
		NSMutableDictionary *newPostDict = [[NSMutableDictionary alloc] initWithObjects: newPosts keyName: kPOST_DICTIONARY_KEY_NAME];
		[posts release];
		posts = [newPostDict mutableCopy];
	}
}

- (void) setPosts: (NSDictionary *) newPosts {
	@synchronized (posts) {
		if (posts != newPosts) {
			[posts release];
			posts = [newPosts mutableCopy];
		}
	}
}

- (NSMutableDictionary *) posts {
    return [[posts retain] autorelease];
}

- (NSArray *) postsArray {
	return [[self posts] allValues];
}

- (NSArray *) selectedPostsArray {
	return [[self filteredPosts] subarrayWithIndexes: [postList selectedRowIndexes]];
}

- (NSArray *) urlsArray {
	return [[self posts] allKeys];
}

- (void) setFilteredPosts: (NSArray *) newFilteredPosts {
	@synchronized (filteredPosts) {
		if (!newFilteredPosts) {
			[filteredPosts release];
			filteredPosts = nil;
		}
		else if (filteredPosts != newFilteredPosts) {
			[filteredPosts release];
			filteredPosts = [newFilteredPosts copy];
		}
	}
}

- (NSArray *) filteredPosts {
    if (!filteredPosts) {
		return [self postsArray];
	}
	
	return [[filteredPosts retain] autorelease];
}

- (void) setCurrentTagFilter: (DCAPITag *) newTagFilter {
    if (currentTagFilter != newTagFilter) {
        [currentTagFilter release];
        currentTagFilter = [newTagFilter copy];
    }
}

- (DCAPITag *) currentTagFilter {
    return [[currentTagFilter retain] autorelease];
}

- (void) setCurrentSearch: (NSString *) newCurrentSearch {
	@synchronized(currentSearch) {
		if (!newCurrentSearch) {
			[currentSearch release];
			currentSearch = nil;
		}
		else if (newCurrentSearch != currentSearch) {
			[currentSearch release];
			currentSearch = [newCurrentSearch copy];
		}
	}
}

- (NSString *) currentSearch {
    return [[currentSearch retain] autorelease];
}

- (IBAction) doSearch: (id) sender {
    if (sender == searchField) {
		[self resetPostView];
		
		NSString *search = [sender stringValue];
		
		[self doSearchForString: search];
		[postList reloadData];
	}
}

- (void) doSearchForString: (NSString *) search {	
	if (!search || [search isEqualToString: [NSString string]]) {
        [self setCurrentSearch: nil];
		[self refreshPostsWithDownload: NO];
		return;
	}
	
	[self setCurrentSearch: search];

#ifdef AWOOSTER_CHANGES
	if (useFullTextSearch) {
		[self beginFullTextSearchForQuery: [self currentSearch]];
	}
	else {
		[self refreshPostsWithDownload: NO];
	}
#else
	/*[self setFilteredPosts: [self filterPosts: [self postsArray] forSearch: [self currentSearch] tags: [self selectedTags]]];
	[postList reloadData];*/
	[self refreshPostsWithDownload: NO];
#endif
}

- (void) makePostListFirstResponder {
	if ([[self filteredPosts] count] > 0) {
		[[NSApp mainWindow] makeFirstResponder: postList];
		[postList selectRow: 0 byExtendingSelection: NO];
	}
}

- (void) makeTagListFirstResponder {
	if ([[self filteredTags] count] > 0) {
		[[NSApp mainWindow] makeFirstResponder: tagList];
		[postList selectRow: 0 byExtendingSelection: NO];
	}	
}

- (void) endTagListEditing {
	[tagList abortEditing];
}

- (IBAction) toggleStatusViewToIndexing { 	
	[statusTextView removeFromSuperview];
	[statusView addSubview: indexingProgressView];
}

- (IBAction) toggleStatusViewToStatusText  { 	
	[indexingProgressView removeFromSuperview];
	[statusView addSubview: statusTextView];
}

- (void) scrollWebViewDown {
	//[webView pageDown: self];
}

- (IBAction) openMainWindow: (id) sender {
	[mainWindow makeKeyAndOrderFront: self];
}

- (IBAction) toggleWebPreview: (id) sender {
	if ([webViewBezel superview]) {
		lastPostListBezelFrame = [postListBezel frame];
		[[webViewBezel retain] removeFromSuperview];
		[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: kBLANK_URL]]];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: NO] forKey: kSHOW_WEB_PREVIEW_DEFAULTS_KEY];
		[statusText setStringValue: [NSString string]];
	}
	else {
		[previewSplitView addSubview: [webViewBezel autorelease]];
		[postListBezel setFrameSize: lastPostListBezelFrame.size];
		[previewSplitView adjustSubviews];
		[self previewSelectedLinks];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: YES] forKey: kSHOW_WEB_PREVIEW_DEFAULTS_KEY];
	}
}

- (void) splitView: (NSSplitView *) sender resizeSubviewsWithOldSize: (NSSize) oldSize {
	[previewSplitView adjustSubviews];
}

- (IBAction) setSearchTypeToBasic: (id) sender {
	[[searchField cell] setPlaceholderString: NSLocalizedString(@"Basic Search", @"Search field placeholder text for basic search.")];

	[[searchMenu itemWithTag: 0] setState: NSOnState];
	[[searchMenu itemWithTag: 1] setState: NSOffState];
	[[searchMenu itemWithTag: 2] setState: NSOffState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = NO;
    useFullTextSearch = NO;

	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];

	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithInt: DCBasicSearchType] forKey: kSEARCH_TYPE_DEFAULTS_KEY];
}

- (IBAction) setSearchTypeToExtended: (id) sender {
	[[searchField cell] setPlaceholderString: NSLocalizedString(@"Extended Search", @"Search field placeholder text for extended search.")];

	[[searchMenu itemWithTag: 0] setState: NSOffState];
	[[searchMenu itemWithTag: 1] setState: NSOnState];
	[[searchMenu itemWithTag: 2] setState: NSOffState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = YES;
    useFullTextSearch = NO;
	
	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];

	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithInt: DCExtendedSearchType] forKey: kSEARCH_TYPE_DEFAULTS_KEY];
}

#pragma mark Full Text Search
#ifdef AWOOSTER_CHANGES
- (IBAction) setSearchTypeToFullText: (id) sender  {
	[[searchField cell] setPlaceholderString: NSLocalizedString(@"Full Text Search", @"Search field placeholder text for full text search.")];
	
	[[searchMenu itemWithTag: 0] setState: NSOffState];
	[[searchMenu itemWithTag: 1] setState: NSOffState];
	[[searchMenu itemWithTag: 2] setState: NSOnState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = NO;
    useFullTextSearch = YES;
	
	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
	
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithInt: DCFullTextSearchType] forKey: kSEARCH_TYPE_DEFAULTS_KEY];
}

- (void) beginFullTextSearchForQuery: (NSString *) query {
    if (!query || [query isEqualToString: [NSString string]]) {
		return;
	}
        
	NSDictionary *searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
		self, @"anObject",
		NSStringFromSelector(@selector(filterPostsForFullTextSearchResult:)), @"aSelector",
		query, @"query",
		[self urlsArray], @"urlArray",
		nil];
			
	[NSThread detachNewThreadSelector:@selector(search:)
		toTarget:textIndex
		withObject:searchDict];
							   
	[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO];
}

- (IBAction) indexAll: (id) sender
{
    NSEnumerator *postEnum = [[self postsArray] objectEnumerator];
    DCAPIPost *currentPost;
    NSMutableArray *postURLs = [[NSMutableArray alloc] init];
    while ((currentPost = [postEnum nextObject]) != nil) {
        [postURLs addObject: [[currentPost URL] copy]];
    }
    NSDictionary *searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
        self, @"anObject",
        NSStringFromSelector(@selector(updateIndexing:)), @"aSelector",
        postURLs, @"urls",
        nil];
		
    [NSThread detachNewThreadSelector:@selector(index:)
                             toTarget:textIndex
                           withObject:searchDict];
}

- (IBAction) indexSelected: (id) sender {
    NSMutableArray *postURLs = [[NSMutableArray alloc] init];
    NSArray *postArray = [self filteredPosts];
    
    if ([postList selectedRow] > -1 && [postList selectedRow] < [postArray count]) {
        DCAPIPost *post = [postArray objectAtIndex: [postList selectedRow]];
        [postURLs addObject: [[post URL] copy]];
    }
    
    NSDictionary *searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
        self, @"anObject",
        NSStringFromSelector(@selector(updateIndexing:)), @"aSelector",
        postURLs, @"urls",
        nil];
    [NSThread detachNewThreadSelector:@selector(index:)
                             toTarget:textIndex
                           withObject:[[searchDict copy] autorelease]];
}

- (void) fullTextIndexBeganIndexingDocumentList: (NSArray *) documentList {
	[self toggleStatusViewToIndexing];
	[indexingProgressBar setMaxValue: [documentList count]];
}

- (void) fullTextIndexIndexedDocumentWithURL: (NSURL *) url {
	[indexingProgressBar incrementBy: 1];
} 

- (void) fullTextIndexFinishedIndexingDocumentList: (NSArray *) documentList {
	[self toggleStatusViewToStatusText];
	[indexingProgressBar setDoubleValue: 0.0];
}

#endif

- (IBAction) openSelected: (id) sender {
    int selectedRow = [postList selectedRow];
    
    NSArray *postArray = [self filteredPosts];
    
    if (selectedRow > -1 && selectedRow < [postArray count]) {
        DCAPIPost *post = [postArray objectAtIndex: selectedRow];
		
		LSLaunchURLSpec openURLSpec;
		openURLSpec.appURL = nil;
		openURLSpec.passThruParams = nil;
		openURLSpec.asyncRefCon = nil;
		openURLSpec.launchFlags = nil;
		
		BOOL openInBG = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kOPEN_URLS_IN_BACKGROUND_DEFAULTS_KEY] boolValue];
		unsigned int alternatePressed = [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask;
		
		if (openInBG && !alternatePressed || !openInBG && alternatePressed) {
			openURLSpec.launchFlags = kLSLaunchDontSwitch;
		}
		else {
			openURLSpec.launchFlags = nil;
		}
		
		openURLSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObjects: [post URL], nil];
		
		LSOpenFromURLSpec(&openURLSpec, nil);
		
		[post incrementVisitCount];
    }
}

- (int) numberOfRowsInTableView: (NSTableView *) view {
    int count = 0;
    
    if (view == postList) {
        count = [[self filteredPosts] count];
    }
    else if (view == tagList) {
        count = [[self filteredTags] count] + 1;
    }
    
    return count;
}

- (id) tableView: (NSTableView *) view objectValueForTableColumn: (NSTableColumn *) col row: (int) row {
    static NSDictionary *info = nil;
	
    if (nil == info) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
        info = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
        [style release];
    }

	if (view == postList) {
        DCAPIPost *post = [[self filteredPosts] objectAtIndex: row];
        NSString *identifier = [col identifier];
        		
        if (post) {
            id value = [post valueForKey: identifier];
			
			if ([value isKindOfClass: [NSString class]]) {
				return [[[NSAttributedString alloc] initWithString: value attributes: info] autorelease];
			}
			
            return value;
        }
    }
    else if (view == tagList) {
        if (row == 0) {
			return [NSString stringWithFormat: NSLocalizedString(@"All (%d Tags)", @"Text for 'all tags' option in tag list"), [[self filteredTags] count]];
        }
        
        return [[self filteredTags] objectAtIndex: row - 1];
    }
    
    return nil;
}

- (BOOL) tableView: (NSTableView *) aTableView shouldEditTableColumn: (NSTableColumn *) aTableColumn row: (int) rowIndex {
	if (aTableView == tagList && rowIndex == 0) {
		return NO;
	}
	
	return YES;
}

- (void) tableView: (NSTableView *) view setObjectValue: (id) object forTableColumn: (NSTableColumn *) col row: (int) row {
	if (view == tagList) {
		DCAPITag *changedTag = [[self filteredTags] objectAtIndex: row - 1];
		DCAPITag *originalTag = [[self tags] objectForKey: [changedTag name]];
		NSString *originalName = [originalTag name];
				
		if (![originalName isEqualToString: [object name]]) {
			[self renameTag: originalName to: [object name] withUpload: YES];
		}
	}
	else if (view == postList) {
		DCAPIPost *changedPost = [[self filteredPosts] objectAtIndex: row];
		[changedPost setRating: object];
		
		[self refreshPostsWithDownload: NO];
		[self refreshTags];
		
		[NSThread detachNewThreadSelector: @selector(addPost:) toTarget: [self client] withObject: changedPost];
	}
}

- (BOOL) tableView: (NSTableView *) tableView writeRows: (NSArray *) rows toPasteboard: (NSPasteboard *) pboard {	
	if ([tableView respondsToSelector: @selector(lastClickWasInDisabledColumn)] && [(SFHFTableView *) tableView lastClickWasInDisabledColumn]) {
		return NO;
	}
	
	if (tableView == postList) {
 		[pboard declareTypes: [NSArray arrayWithObjects: kDCAPIPostPboardType,
 														 kWebURLsWithTitlesPboardType,
 														 NSURLPboardType,
 														 kWebURLPboardType,
 														 kWebURLNamePboardType,
 														 NSStringPboardType, nil] owner: self];
		
		NSNumber *currentPostIndex = [rows objectAtIndex: 0];
		DCAPIPost *currentPost = [[self filteredPosts] objectAtIndex: [currentPostIndex unsignedIntValue]];
		[pboard setData: [NSKeyedArchiver archivedDataWithRootObject: currentPost] forType: kDCAPIPostPboardType];
		
		NSURL *currentURL = [currentPost URL];
		[pboard setString: [currentURL absoluteString] forType: NSStringPboardType];
		[currentURL writeToPasteboard: pboard];

		NSString *currentTitle = [currentPost description];

		id plist = [NSArray arrayWithObjects:[NSArray arrayWithObject:[currentURL absoluteString]],
 											 [NSArray arrayWithObject:[currentPost description]],
 											 nil];
 		NSData * data = [NSPropertyListSerialization dataFromPropertyList:plist
 							format:NSPropertyListXMLFormat_v1_0
 							errorDescription:NULL];
 		NSString * string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
 		
 		[pboard setPropertyList:plist forType:kWebURLsWithTitlesPboardType];
 		[pboard setString:string forType:kWebURLsWithTitlesPboardType];
 		[pboard setData:data forType:kWebURLsWithTitlesPboardType];
 		
 		[pboard setString:[currentURL absoluteString] forType:kWebURLPboardType];
 		[pboard setString:currentTitle forType:kWebURLNamePboardType];

		return YES;
	}
	
	return NO;
}

- (NSDragOperation) tableView: (NSTableView *) tableView validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) operation {
	if (tableView == tagList && postList == [info draggingSource] && operation == NSTableViewDropOn && row > 0 && row <= [[self filteredTags] count]) {
		return NSDragOperationLink;
	}
	
	return NSDragOperationNone;
}

- (BOOL) tableView: (NSTableView *) tableView acceptDrop: (id <NSDraggingInfo>) info row: (int) row dropOperation: (NSTableViewDropOperation) operation {
#warning modify if tableView:validateDrop:proposedRow:proposedOperation returns for more than just tag assignment
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType: kDCAPIPostPboardType];
	
	DCAPIPost *unarchivedPost = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	NSString *newTag = [[[self filteredTags] objectAtIndex: row - 1] name];
	DCAPIPost *post = [[self posts] objectForKey: [unarchivedPost valueForKey: kPOST_DICTIONARY_KEY_NAME]];
	
	if (post) {
		[post addTagNamed: newTag];
		[self refreshTags];
		[NSThread detachNewThreadSelector: @selector(addPost:) toTarget: [self client] withObject: post];
		return YES;
	}
		
	return NO;
}

- (void) tableView: (NSTableView *) tableView didClickTableColumn: (NSTableColumn *) tableColumn {
	if (tableView == postList) {
		[self refreshPostsWithDownload: NO];

		NSArray *descriptors = [postList sortDescriptors];
		NSData *descriptorData = [NSArchiver archivedDataWithRootObject: descriptors];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: descriptorData forKey: kPOST_LIST_SORT_DEFAULTS_KEY];
	}
}

#ifdef FAVICON_SUPPORT
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
 	if(aTableView == postList) {
 		if([[aTableColumn identifier] isEqualToString:@"description"]) {
 			DCAPIPost *currentPost = [[self filteredPosts] objectAtIndex: rowIndex];
 						
			if ([aCell isKindOfClass: [EBIconAndTextCell class]]) {				
				/*if ([aCell favicon]) {
					return;
				}*/
				
				NSImage *icon = [[SFHFFaviconCache sharedFaviconCache] faviconForURL: [currentPost URL] forceRefresh: NO];
				//NSImage *icon = nil;
				
				if (!icon) {
					icon = [[SFHFFaviconCache sharedFaviconCache] defaultFavicon];
				}
				
				[(EBIconAndTextCell *) aCell setFavicon: icon];
			}
		}
 	}
}
#endif

// ----- beg implementation for postList tooltips -----
- (NSString *)tableView:(SFHFTableView *)tableView tooltipForItem:(id)item {
	if (tableView == postList) {
		NSString *toolTip = [item extended];
		if (toolTip) {
			return toolTip;
		} else {
			return @"No extended description available";
		}
	}
	return nil;
}

- (id)tableView:(SFHFTableView *)tableView itemAtRow:(int)row {	
	if (tableView == postList) {
		DCAPIPost *post = [[self filteredPosts] objectAtIndex: row];
		if (post) {
			return post;
		}
	}
	
	return nil;
}

// ----- end implementation for postList tooltips -----

- (IBAction) copyAsTag: (id) sender {
	NSIndexSet *rows = [postList selectedRowIndexes];

	unsigned int currentIndex = [rows firstIndex];
	
	if (currentIndex == NSNotFound) {
		return;
	}
	
	DCAPIPost *currentPost = [[self filteredPosts] objectAtIndex: currentIndex];
	NSURL *currentURL = [currentPost URL];

	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes: [NSArray arrayWithObjects:NSStringPboardType, nil] owner: self];
	
	[pboard setString: [NSString stringWithFormat: [[NSBundle mainBundle] objectForInfoDictionaryKey: @"DCHTMLTagFormat"], [currentURL absoluteString], [currentPost description]] forType: NSStringPboardType];
}

- (void) updateTagFilterFromSelection {
    int selectedRow = [tagList selectedRow];
	NSArray *tagArray = [self tagsArray];
	
	if (selectedRow > 0 && selectedRow <= [tagArray count]) {
		DCAPITag *tag = [tagArray objectAtIndex: selectedRow - 1];
		[self setCurrentTagFilter: tag];
	}
	else {
		[self setCurrentTagFilter: nil];
	}
}

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification {
    id table = [aNotification object];
    
    if (table == tagList) {	
		[self setCurrentSearch: nil];
		[searchField setStringValue: [NSString string]];
		[self resetPostView];
		[self refreshPostsWithDownload: NO];
    }
    else if (table == postList) {
		[self previewSelectedLinks];
    }
}

- (BOOL) typeSelectTableView: (id) tableView shouldPerformSearch: (NSString *) search {
	if (tableView == postList) {
		return NO;
	}
	
	return YES;
}

- (void) previewSelectedLinks {
	#warning Is this the best way to determine if the web view is visible or not?
	if (![webViewBezel superview]) {
		return;
	}
	
	int selectedRow = [postList selectedRow];
	
	NSArray *postArray = [self filteredPosts];
	
	if (selectedRow > -1 && selectedRow < [postArray count]) {
		DCAPIPost *post = [postArray objectAtIndex: selectedRow];
		NSURL *url = [post URL];
		
		if (url == nil) {
			NSLog(@"ERROR: nil URL for post: %@", [post description]);
			return;
		}
		
		[statusText setStringValue: [url description]];
		
		[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: url]];
	}
	else {
		[self resetPostView];
	}
}

- (void) resetPostView {
	[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: kBLANK_URL]]];
	[statusText setStringValue: [NSString string]];
	[postList deselectAll: self];
}

- (void) webView: (WebView *) sender didFinishLoadForFrame: (WebFrame *) frame {
    if (frame == [sender mainFrame]){
		[spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: YES];
#ifdef AWOOSTER_CHANGES
        // Check if the WebDocumentView supports the WebDocumentText protocol.
        if ([[[frame frameView] documentView] 
             respondsToSelector:@selector(string)]) {
            NSURL *url = [[[frame dataSource] request] URL];
            if ([[[frame dataSource] representation] 
                canProvideDocumentSource] &&
                [url description] != @"about:blank") {
                NSString *contents = [[NSString alloc] initWithString: 
                    [[[frame dataSource] representation] documentSource]];
                [textIndex addDocumentToIndex: url
                                  withContent: contents
                                  inBatchMode: NO];
            }
        }
#endif
    }
}

- (void) webView: (WebView *) sender didStartProvisionalLoadForFrame: (WebFrame *) frame {
    if (frame == [sender mainFrame] && [[[[frame provisionalDataSource] request] URL] absoluteString] != kBLANK_URL){
		[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) withObject: self waitUntilDone: YES];
	}
}

- (void) login {
    NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *user = [values valueForKey: kUSERNAME_DEFAULTS_KEY];
    NSString *apiURLString = [values valueForKey: kAPI_URL_DEFAULTS_KEY];
	NSURL *apiURL = [NSURL URLWithString: apiURLString];
	NSError *loginError;

	BOOL autologin = [[values valueForKey: kAUTOLOGIN_DEFAULTS_KEY] boolValue];

	if (user) {
		[loginProperties setObject: user forKey: @"username"];

		NSString *password = [SFHFKeychainUtils getWebPasswordForUser: user URL: apiURL domain: kDEFAULT_SECURITY_DOMAIN itemReference: NULL];
				
		if (password) {
			if (autologin) {
				if ([self loginWithUsername: user password: password APIURL: apiURL error: &loginError])
					return;
				else if([loginError code] == -1012)
					[loginErrorText setStringValue: ERR_LOGIN_AUTHENTICATION];
				else 
					[loginErrorText setStringValue: ERR_LOGIN_OTHER];
			}
			[loginProperties setObject: password forKey: @"password"];
		}
	}
	
	[loginProperties setObject: [NSNumber numberWithBool: autologin] forKey: @"autologin"];
	[loginPanel makeKeyAndOrderFront: self];
}

- (IBAction) loginFromPanel: (id) sender {
	[loginErrorText setStringValue: @""];
	[loginErrorText display];
	[loginSpinner startAnimation: self];
	[loginController commitEditing];

	NSString *username = [loginProperties objectForKey: @"username"];
	NSString *password = [loginProperties objectForKey: @"password"];
	BOOL autologin = [[loginProperties objectForKey: @"autologin"] boolValue];
	NSError *loginError;

	if (!username || !password) {
		return;
	}

    NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];	
    NSString *apiURLString = [values valueForKey: kAPI_URL_DEFAULTS_KEY];
	NSURL *apiURL = [NSURL URLWithString: apiURLString];	
	
	/* Write username to defaults */
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	[defaults setObject: username forKey: kUSERNAME_DEFAULTS_KEY];
	
	/* If we're supposed to autologin, remember that */
	[defaults setObject: [NSNumber numberWithBool: autologin] forKey: kAUTOLOGIN_DEFAULTS_KEY];
	
	/* Write password to keychain */
	//[SFHFKeychainUtils addWebPassword: password forUser: username URL: apiURL domain: kDEFAULT_SECURITY_DOMAIN];
	
	//NSString *pass = [SFHFKeychainUtils getWebPasswordForUser: username URL: apiURL domain: kDEFAULT_SECURITY_DOMAIN itemReference: nil];
	//NSLog(@"password in keychain is now: %@", pass);
	
	/* Make sure the password gets updated in both the keychain and the shared NSURLCredentialStorage used by NSURLConnection */
	NSURLCredential *credential = [NSURLCredential credentialWithUser: username password: password persistence: NSURLCredentialPersistencePermanent];
	NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost: [apiURL host] port: 0 protocol: @"http" realm: kDEFAULT_SECURITY_DOMAIN authenticationMethod: NSURLAuthenticationMethodDefault];
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential: credential forProtectionSpace: protectionSpace];
	
	if([self loginWithUsername: username password: password APIURL: apiURL error: &loginError]) {
		[loginPanel close];
	}
	else {
		if([loginError code] == -1012)
			[loginErrorText setStringValue: ERR_LOGIN_AUTHENTICATION];
		else
			[loginErrorText setStringValue: ERR_LOGIN_OTHER];
	}
	
	[loginSpinner stopAnimation: self];
}

- (BOOL) loginWithUsername: (NSString *) username password: (NSString *) password APIURL: (NSURL *) APIURL error: (NSError **) error {
    if(!client) {
		DCAPIClient *dcClient = [[DCAPIClient alloc] initWithAPIURL: APIURL username: username password: password delegate: self];
		[self setClient: dcClient];
		[dcClient release];
	}
	
	/* Get last update time.  Right now this is just used to verify authentication. */
	[client requestLastUpdateTime: error];

	if(*error) {
		return NO;
	}
	
	[mainWindow makeKeyAndOrderFront: self];
	[mainWindow setTitle: [NSString stringWithFormat: [[NSBundle mainBundle] objectForInfoDictionaryKey: @"DCWindowTitleFormat"], username]];
	[NSThread detachNewThreadSelector: @selector(refreshAll) toTarget: self withObject: nil];
		
	return YES;
}

- (IBAction) cancelLogin: (id) sender {
    [[NSUserDefaultsController sharedUserDefaultsController] revert: self];
    [NSApp terminate: self];
}

- (IBAction) openRegistrationURL: (id) sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: kREGISTRATION_URL]];
}

- (IBAction) addOrDeleteLinks: (id) sender {
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment: clickedSegment];
	
	switch (clickedSegmentTag) {
		case kADD_POST_SEGMENT_TAG:
			[self showPostingInterface: self];
			break;
		case kDELETE_POST_SEGMENT_TAG:
			[self deleteSelectedLinks: self];
			break;
		default:
			break;
	}
}

- (IBAction) showPostingInterface: (id) sender {
	[NSApp activateIgnoringOtherApps: YES];
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSString *type = [pboard availableTypeFromArray: [NSArray arrayWithObjects: NSURLPboardType, NSStringPboardType, nil]];
	
	if (type) {
		NSString *pboardContents = [pboard stringForType: type];

		if ([currentPostProperties objectForKey: @"extended"]) {
			[postingInterface makeFirstResponder: postTagsField];
		}
		else if ([currentPostProperties objectForKey: @"description"]) {
			[postingInterface makeFirstResponder: postExtendedField];
		}
		else if ([currentPostProperties objectForKey: @"url"]) {
			[postingInterface makeFirstResponder: postDescriptionField];
		}
		else if (![currentPostProperties objectForKey: @"url"] && pboardContents && [pboardContents hasPrefix: kHTTP_PROTOCOL_PREFIX]) {
			[currentPostProperties setObject: pboardContents forKey: @"url"];
			[postingInterface makeFirstResponder: postDescriptionField];
		}
		else {
			[postingInterface makeFirstResponder: postURLField];
		}
	}

    [NSApp beginSheet: postingInterface modalForWindow: mainWindow modalDelegate: nil didEndSelector: nil contextInfo: nil];

    [NSApp runModalForWindow: postingInterface];

    // Sheet is up here.

    [NSApp endSheet: postingInterface];

    [postingInterface orderOut: self];	
}

- (BOOL) splitView: (NSSplitView *) sender canCollapseSubview: (NSView *) subview {
	return YES;
}

- (IBAction) closePostingInterface: (id) sender {
	[NSApp stopModal];

	[currentPostProperties removeObjectForKey: @"url"];
	[currentPostProperties removeObjectForKey: @"description"];
	[currentPostProperties removeObjectForKey: @"extended"];
	[currentPostProperties removeObjectForKey: @"tags"];
	[currentPostProperties removeObjectForKey: @"date"];
	
	[[NSApp mainWindow] makeFirstResponder: [[NSApp mainWindow] initialFirstResponder]];
}


- (void) postNewNNWLink: (NSAppleEventDescriptor *) event withReplyEvent: (NSAppleEventDescriptor *) reply {
    NSAppleEventDescriptor *recordDescriptor = [event descriptorForKeyword: keyDirectObject];
    NSString *title = [[recordDescriptor descriptorForKeyword: DCNNWPostTitle] stringValue];
    //NSString *body = [[recordDescriptor descriptorForKeyword: DCNNWPostDescription] stringValue];
    NSString *summary = [[recordDescriptor descriptorForKeyword: DCNNWPostSummary] stringValue];
    NSString *link = [[recordDescriptor descriptorForKeyword: DCNNWPostLink] stringValue];
    NSString *permalink = [[recordDescriptor descriptorForKeyword: DCNNWPostPermalink] stringValue];
    NSString *commentsURL = [[recordDescriptor descriptorForKeyword: DCNNWPostCommentsURL] stringValue];
	NSString *subject = [[recordDescriptor descriptorForKeyword: DCNNWPostSubject] stringValue];
    /*NSString *sourceName = [[recordDescriptor descriptorForKeyword: DCNNWPostSourceName] stringValue];
    NSString *sourceHomeURL = [[recordDescriptor descriptorForKeyword: DCNNWPostSourceHomeURL] stringValue];
    NSString *sourceFeedURL = [[recordDescriptor descriptorForKeyword: DCNNWPostSourceFeedURL] stringValue];*/

	[currentPostProperties setObject: title forKey: @"description"];
	
	if (summary) {
		[currentPostProperties setObject: summary forKey: @"extended"];
	}
	
	if (subject) {
		[currentPostProperties setObject: [subject lowercaseString] forKey: @"tags"];
	}
	
    /*if (body == nil) {
    	[currentPostProperties setObject: summary forKey: @"extended"];
    }
    else {
    	[currentPostProperties setObject: body forKey: @"extended"];
    }*/
    
    if (permalink == nil) {
        if (commentsURL == nil) {
			[currentPostProperties setObject: link forKey: @"url"];
        }
        else {
			[currentPostProperties setObject: commentsURL forKey: @"url"];
        }
    }
    else {
		[currentPostProperties setObject: permalink forKey: @"url"];
    }
    
	[self showPostingInterface: self];
}

- (void) insertPost: (DCAPIPost *) newPost {
	[[self posts] setValue: newPost forKey: [newPost valueForKey: kPOST_DICTIONARY_KEY_NAME]];	
	[self refreshPostsWithDownload: NO];
	[self refreshTags];
}

- (IBAction) postNewLink: (id) sender {
	NSURL *postURL = [NSURL URLWithString: [currentPostProperties objectForKey: @"url"]];
	NSString *postDescription = [currentPostProperties objectForKey: @"description"];
	NSString *postExtended = [currentPostProperties objectForKey: @"extended"];
	NSString *postTags = [currentPostProperties objectForKey: @"tags"];

	NSDate *postDate = [currentPostProperties objectForKey: @"date"];

	if (!postDate) {
		postDate = [NSCalendarDate date];
	}
	
	DCAPIPost *newPost = [[DCAPIPost alloc] initWithURL: postURL description: postDescription extended: postExtended date: postDate tags: nil urlHash: nil];
	[newPost setTagsFromString: postTags];
	
	[NSThread detachNewThreadSelector: @selector(performAsyncAddOfPost:) toTarget: self withObject: newPost];
	
	[[SFHFFaviconCache sharedFaviconCache] faviconForURL: postURL forceRefresh: YES];
	
	[self closePostingInterface: self];
	[self insertPost: newPost];
	[newPost release];
}

- (void) performAsyncAddOfPost: (DCAPIPost *) newPost {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[SFHFFaviconCache sharedFaviconCache] faviconForURL: [newPost URL] forceRefresh: YES];
	[[self client] addPost: newPost];
	[pool release];
}

- (void)postNewLinkWithPasteboard:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    NSURL *url = nil;
    NSArray *types = [pboard types];
    
    if ([types containsObject:NSURLPboardType])
    {
        url = [NSURL URLFromPasteboard:pboard];
    }
    else if ([types containsObject:NSStringPboardType])
    {
        url = [NSURL URLWithString:[pboard stringForType:NSStringPboardType]];
    }
	else {
		return;
	}
    
    NSString *urlString = [url absoluteString];
    if (urlString != nil) {
        [currentPostProperties setObject:urlString forKey: @"url"];
        [self showPostingInterface:self];
    }
    else
    {
        // app window comes to front when service is triggered, but app does not become active.
        // still need to activate app before alert is shown.  Very confusing if we leave it to the user.
        [NSApp activateIgnoringOtherApps:YES]; 
        (void)NSRunAlertPanel(NSLocalizedString(@"Post selection failed", @"Title of alert indicating error during Post via Cocoalicious service"),
                              NSLocalizedString(@"Couldn't make selection into a URL.", @"Message indicating couldn't post selection during Post via Cocoalicious service"),
                              NSLocalizedString(@"OK", @"OK"), nil, nil);
    }
}

- (IBAction) postCurrentSafariURL: (id) sender {
	NSDictionary *errorInfo = nil;
	NSAppleEventDescriptor *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
	
	NSAppleEventDescriptor *result = [safariScript callHandler: kDCSafariGetCurrentURL withArguments: arguments errorInfo: &errorInfo];
	
	NSString *scriptResult = [result stringValue];
	
	/* Check for errors in running the handler */
    if (errorInfo) {
        [self handleScriptError: errorInfo];
    }
    /* Check the handler's return value */
    else if ([scriptResult isEqualToString: kScriptError]) {
        NSRunAlertPanel(NSLocalizedString(@"Script Failure", @"Title on script failure window."), [NSString stringWithFormat: @"%@ %d", NSLocalizedString(@"The script failed:", @"Message on script failure window."), scriptResult], NSLocalizedString(@"OK", @""), nil, nil);
    }
	
	NSString *URLString = [[scriptResult componentsSeparatedByString: @"***"] objectAtIndex: 1];
	
	if (URLString) {
		[currentPostProperties setObject: URLString forKey: @"url"];
	}
	
	NSString *description = [[scriptResult componentsSeparatedByString: @"***"] objectAtIndex: 0];
	
	if (description) {
		[currentPostProperties setObject: description forKey: @"description"];
	}

	errorInfo = nil;

	/* reuse args */
	result = [safariScript callHandler: kDCSafariGetCurrentSelection withArguments: arguments errorInfo: &errorInfo];
	scriptResult = [result stringValue];

    if (errorInfo) {
        [self handleScriptError: errorInfo];
    }
    /* Check the handler's return value */
    else if ([scriptResult isEqualToString: kScriptError]) {
		#warning Put error here
	}
	
	if (scriptResult && ![scriptResult isEqualToString: [NSString string]]) {
		[currentPostProperties setObject: scriptResult forKey: @"extended"];
	}
	
	[self showPostingInterface: self];
	
	[arguments release];
}

- (IBAction) editSelectedLinks: (id) sender {
    int selectedRow = [postList selectedRow];

	if (selectedRow > -1) {
		DCAPIPost *selectedPost = [[self filteredPosts] objectAtIndex: selectedRow];
		
		NSString *URLString = [[selectedPost URL] absoluteString];
		
		if (URLString) {
			[currentPostProperties setObject: URLString forKey: @"url"];
		}
		
		NSString *description = [selectedPost description];
		
		if (description) {
			[currentPostProperties setObject: description forKey: @"description"];
		}
		
		NSString *extended = [selectedPost extended];
		
		if (extended) {
			[currentPostProperties setObject: extended forKey: @"extended"];
		}
		
		NSString *tagString = [selectedPost tagsAsString];
		
		if (tagString) {
			[currentPostProperties setObject: tagString forKey: @"tags"];
		}
		
		NSDate *postDate = [selectedPost date];
		
		if (postDate) {
			[currentPostProperties setObject: postDate forKey: @"date"];
		}
		
		[self showPostingInterface: self];
	}
}

- (IBAction) deleteSelectedLinks: (id) sender {
	int selectedRow = [postList selectedRow];

	if (selectedRow > -1) {
		DCAPIPost *selectedPost = [[self filteredPosts] objectAtIndex: selectedRow];
		[[self posts] removeObjectForKey: [selectedPost valueForKey: kPOST_DICTIONARY_KEY_NAME]];
		[NSThread detachNewThreadSelector: @selector(deletePostWithURL:) toTarget: [self client] withObject: [selectedPost URL]];
		[self refreshPostsWithDownload: NO];
		[self refreshTags];
	}
}

- (void) handleScriptError: (NSDictionary *) errorInfo {
#warning if safariScript = nil disable menu item
    NSString *errorMessage = [errorInfo objectForKey: NSAppleScriptErrorBriefMessage];
    NSNumber *errorNumber = [errorInfo objectForKey: NSAppleScriptErrorNumber];
	
    NSRunAlertPanel(NSLocalizedString(@"Script Error", @"Title on script error window."), [NSString stringWithFormat: @"%@: %@", NSLocalizedString(@"The script produced an error", @"Message on script error window."), errorNumber, errorMessage], NSLocalizedString(@"OK", @""), nil, nil);
}

- (void) windowWillClose: (NSNotification *) aNotification {
    NSWindow *theWindow = [aNotification object];
    
    if (theWindow == preferencesWindow) {
        [(NSUserDefaultsController *) [NSUserDefaultsController sharedUserDefaultsController] save: self];
    }
}

- (BOOL) application: (NSApplication *) theApplication openFile: (NSString *) filename {
	return NO;
}

- (BOOL) validateMenuItem: (NSMenuItem *) anItem { 
	if ([anItem action] == @selector(copyAsTag:) && ([postList numberOfSelectedRows] < 1 || [[NSApp mainWindow] firstResponder] != postList)) {
		return NO;
	}
	else if (([anItem action] == @selector(editSelectedLinks:) || [anItem action] == @selector(deleteSelectedLinks:)) && [postList numberOfSelectedRows] < 1) {
		return NO;
	}
	
	return YES;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication {
	return NO;
}

- (void) applicationDidResignActive: (NSNotification *) aNotification {
	float alphaValue = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kDEACTIVATE_ALPHA_DEFAULTS_KEY] floatValue];
	[mainWindow setAlphaValue: alphaValue];
}

- (void) applicationDidBecomeActive: (NSNotification *) aNotification {
	[mainWindow setAlphaValue: 1.0];
}

- (BOOL) applicationShouldHandleReopen: (NSApplication *) theApplication hasVisibleWindows: (BOOL) visibleWindows {
	if (![mainWindow isVisible]  && ![loginPanel isVisible]) {
		[mainWindow makeKeyAndOrderFront: self];
	}
	
	return NO;
}

- (void) textDidBeginEditing: (NSNotification *) aNotification {
	lastTextChangeWasCompletion = NO;
}

- (void) textDidChange: (NSNotification *) aNotification {
	if ([aNotification object] == postTagsField) {
		BOOL shouldAutocomplete = [(NSNumber *) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kAUTOMATICALLY_COMPLETE_TAGS_DEFAULTS_KEY] boolValue];

		if (!shouldAutocomplete) {
			return;
		}

		NSTimeInterval autocompleteDelay = (NSTimeInterval) [(NSNumber *) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kTAG_AUTOCOMPLETION_DELAY_DEFAULTS_KEY] floatValue];

		if (autocompleteTimer) {
			[autocompleteTimer invalidate];
			[autocompleteTimer release];
			autocompleteTimer = nil;
		}

		unichar currentEventChar = [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex: 0];

		if (lastTextChangeWasCompletion || currentEventChar == NSDeleteCharacter || currentEventChar == NSDeleteFunctionKey) {
			lastTextChangeWasCompletion = NO;
		}
		else {
			autocompleteTimer = [NSTimer timerWithTimeInterval: (NSTimeInterval) autocompleteDelay target: self selector: @selector(doTimedAutocomplete:) userInfo: nil repeats: NO];
			[autocompleteTimer retain];
			[[NSRunLoop currentRunLoop] addTimer: autocompleteTimer forMode: NSModalPanelRunLoopMode];
		}
	}
}

- (void) doTimedAutocomplete: (NSTimer *) timer {
	[postTagsField complete: self];
}

- (void) textViewFinishedCompletion: (NSTextView *) textView {
	lastTextChangeWasCompletion = YES;
}

- (void) textViewCancelledCompletion: (NSTextView *) textView {
	lastTextChangeWasCompletion = YES;
}

// Delegate for post sheet's tags text view
- (NSArray *)textView:(NSTextView *)textView
		  completions:(NSArray *)words
  forPartialWordRange:(NSRange)charRange
  indexOfSelectedItem:(int *)index
{
#warning [FS] For accounts with massive numbers of tags, this naive implementation may prove slow.
	// However, it would be wise to profile first.
	
	NSString *prefix = [[[textView string] substringWithRange: charRange] lowercaseString];
	NSMutableArray *completions = [NSMutableArray array];
	
	NSEnumerator *tagEnumerator = [[self tagsArray] objectEnumerator];
	DCAPITag *tag;
	while(tag = [tagEnumerator nextObject]) {
		if([[[tag name] lowercaseString] hasPrefix: prefix])
			[completions addObject: [[tag name] copy]];
	}
	return completions;
}

- (void) dealloc {
    [client release];
    [tags release];
    [posts release];
	[filteredPosts release];
    [currentTagFilter release];
	[currentPostProperties release];
	[loginProperties release];
    [currentSearch release];
#ifdef AWOOSTER_CHANGES
    [textIndex release];
#endif
	[safariScript release];
	[dockMenu release];
    [super dealloc];
}

@end
