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

@implementation AppController

+ (void) initialize {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: kDEFAULT_API_URL forKey: kAPI_URL_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithBool: NO] forKey: kOPEN_URLS_IN_BACKGROUND_DEFAULTS_KEY];
	[dictionary setObject: [NSNumber numberWithFloat: 1.0] forKey: kDEACTIVATE_ALPHA_DEFAULTS_KEY];
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
	[self sizeBezelSubviews];
	[self setupToolbar];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	/* Support for NetNewsWire External Weblog Editor Interface */
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler: self andSelector: @selector(postNewNNWLink:withReplyEvent:) forEventClass: DCNNWPostAppleEventClass andEventID: DCNNWPostAppleEventID];
	
	NSString *safariScriptPath = [[NSBundle mainBundle] pathForResource: kDCSafariScriptLibrary ofType: kDCScriptType];
	NSURL *safariScriptURL = [NSURL fileURLWithPath: safariScriptPath];
	NSDictionary *errorInfo = nil;
	
	safariScript = [[NSAppleScript alloc] initWithContentsOfURL: safariScriptURL error: &errorInfo];
	
	if (!safariScript || errorInfo) {
        [self handleScriptError: errorInfo];
    }
	
	[postList setDoubleAction: @selector(openSelected:)];
    
    [self setPosts: [NSArray array]];
    [self setTags: [NSArray array]];
    [self setDates: [NSArray array]];
    
    [self setupTaglist];
	[self setupPostlist];
    
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
}

- (void) setupToolbar {
	[refreshButton setSegmentCount: 1];
	[refreshButton setWidth: 22 forSegment: 0];
	NSImage *refreshIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kREFRESH_BUTTON_IMAGE ofType: @"tif"]];
	[[refreshButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[refreshButton setImage: refreshIcon forSegment: 0];
	[refreshIcon release];
	
	[addDeletePostButton setSegmentCount: 2];
	[addDeletePostButton setWidth: 22 forSegment: 0];
	[addDeletePostButton setWidth: 22 forSegment: 1];
	NSImage *addPostIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kADD_POST_BUTTON_IMAGE ofType: @"tif"]];
	NSImage *deletePostIcon = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: kDELETE_POST_BUTTON_IMAGE ofType: @"tif"]];
	[[addDeletePostButton cell] setTrackingMode: NSSegmentSwitchTrackingMomentary];
	[addDeletePostButton setImage: addPostIcon forSegment: 0];
	[addDeletePostButton setImage: deletePostIcon forSegment: 1];
	[[addDeletePostButton cell] setTag: kADD_POST_SEGMENT_TAG forSegment: 0];
	[[addDeletePostButton cell] setTag: kDELETE_POST_SEGMENT_TAG forSegment: 1];
	[addPostIcon release];
	[deletePostIcon release];
		
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

- (void) setupPostlist {    
	[postList setAction: @selector(openSelected:) forKey: NSRightArrowFunctionKey];
	[postList setAction: @selector(makeTagListFirstResponder) forKey: NSLeftArrowFunctionKey];
	[postList setAction: @selector(scrollWebViewDown) forKey: ' '];
	[postList setAction: @selector(deleteSelectedLinks:) forKey: NSDeleteCharacter];
	
	[postList initializeColumnsUsingHeaderCellClass: [SFHFiTunesTableHeaderCell class] formatterClass: nil];

    SFHFTableHeaderCell *cornerCell = [[SFHFiTunesTableHeaderCell alloc] initTextCell: @" "];
	SFHFCornerView *cornerView = [[SFHFCornerView alloc] init];
    [cornerView setCell: cornerCell];
    [postList setCornerView: cornerView];
    [cornerView release];
	[cornerCell release];
	
	NSTableColumn *dateColumn = [postList tableColumnWithIdentifier: @"date"];
	NSCell *dateColumnCell = [dateColumn dataCell];
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

- (IBAction) refresh: (id) sender {
    [NSThread detachNewThreadSelector: @selector(refreshView) toTarget: self withObject: nil];
}

- (void) refreshView {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [spinnyThing performSelectorOnMainThread: @selector(startAnimation:) withObject: self waitUntilDone: NO]; 
    [self refreshAll];
    [spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: NO];
    
    [tagList performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: YES];
    [postList performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: YES];

    [pool release];
}

- (void) refreshTagView {
	@synchronized (self) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) withObject: self waitUntilDone: YES];

		[self refreshTags];
		[tagList reloadData];
		
		[spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: YES];

		[pool release];
	}
}

- (void) refreshTags {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setTags: [[self client] requestTagsFilteredByDate: nil]];
	
	[pool release];
}

- (void) refreshPostView {
    @synchronized (self) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) withObject: self waitUntilDone: YES];

		[self refreshPostsWithDownload: YES];
		[postList reloadData];

		[spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: YES];

		[pool release];
	}
}

- (void) refreshPostsWithDownload: (BOOL) download {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	DCAPITag *tagFilter = [self currentTagFilter];

	NSArray *unfilteredPosts;

	if (download || ![self posts]) {
		unfilteredPosts = [[self client] requestPostsFilteredByTag: nil count: nil];
	}
	else {
		unfilteredPosts = [self posts];
	}
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO selector: @selector(compare:)];
	NSArray *resortedPosts = [unfilteredPosts sortedArrayUsingDescriptors: [NSArray arrayWithObjects: sortDescriptor, nil]];
	
	[self setPosts: resortedPosts];

	NSString *search = [self currentSearch];
	
	NSArray *matchTags = nil;
	
	if (![tagList isRowSelected: 0]) {
		matchTags = [self selectedTags];
	}
	
	if (search || matchTags) {
		[self setFilteredPosts: [self filterPosts: [self posts] forSearch: search tags: matchTags]];
	}
	else {
		[self setFilteredPosts: nil];
	}

	/* Dummy code for working without a network connection */

	/* DCAPIPost *testPost = [[DCAPIPost alloc] initWithURL: [NSURL URLWithString: @"http://www.scifihifi.com"] description: @"Test" extended: @"Test" date: [NSDate date] tags: [NSArray arrayWithObject: @"test"] urlHash: @"sdfasd"];
	[self setPosts: [NSArray arrayWithObject: testPost]];
	[testPost release]; */
	
	[postList reloadData];
	
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
		[selectedTags addObject: [[tags objectAtIndex: currentIndex - 1] name]];
		currentIndex = [selectedRows indexGreaterThanIndex: currentIndex];
	}
	
	return selectedTags;
}

#ifdef AWOOSTER_CHANGES
- (void)updateIndexing: (id)anObject
{
    if (AWOOSTER_DEBUG)
        NSLog(@"updateIndex:");
    
    if ([textIndex indexing] || [textIndex searching]) {
        [spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    } else {
        [spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    }
}

- (void) updatePostFilter: (NSMutableArray *) results
{
    if (AWOOSTER_DEBUG) {
        NSLog(@"updatePostFilter:");
    }
    
	[self setFilteredPosts: results];
    
    if ([textIndex indexing] || [textIndex searching]) {
        [spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    } else {
        [spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) 
                                      withObject: self waitUntilDone: NO]; 
    }
    
	[postList reloadData];
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

- (void) refreshDates {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setDates: [[self client] requestDatesFilteredByTag: nil]];
	
	[pool release];
}

- (void) refreshAll {
	[self refreshTags];
    [self refreshPostsWithDownload: YES];
    [self refreshDates];
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

- (void) setTags: (NSArray *) newTags {
    if (tags != newTags) {
        [tags release];
        tags = [newTags copy];
    }
}

- (NSArray *) tags {
    return [[tags retain] autorelease];
}

- (void) resortTags {
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];
	NSArray *resortedTags = [[self tags] sortedArrayUsingDescriptors: [NSArray arrayWithObjects: sortDescriptor, nil]];
	[sortDescriptor release];
	[self setTags: resortedTags];
	[self updateTagFilterFromSelection];
	NSLog(@"about to reload tag list");
	[tagList reloadData];
}

- (void) setDates: (NSArray *) newDates {
    if (dates != newDates) {
        [dates release];
        dates = [newDates copy];
    }
}

- (NSArray *) dates {
    return [[dates retain] autorelease];
}

- (void) setPosts: (NSArray *) newPosts {
	if (posts != newPosts) {
        [posts release];
        posts = [newPosts copy];
    }
}

- (NSArray *) posts {
    return [[posts retain] autorelease];
}

- (void) setFilteredPosts: (NSArray *) newFilteredPosts {
	if (!newFilteredPosts) {
        [filteredPosts release];
		filteredPosts = nil;
	}
    else if (filteredPosts != newFilteredPosts) {
        [filteredPosts release];
        filteredPosts = [newFilteredPosts copy];
    }
}

- (NSArray *) filteredPosts {
    if (!filteredPosts) {
		return [self posts];
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
	if (!newCurrentSearch) {
        [currentSearch release];
		currentSearch = nil;
	}
	else if (newCurrentSearch != currentSearch) {
        [currentSearch release];
        currentSearch = [newCurrentSearch copy];
    }
}

- (NSString *) currentSearch {
    return [[currentSearch retain] autorelease];
}

- (void) controlTextDidChange: (NSNotification *) aNotification {
    if ([aNotification object] == searchField) {
		[self resetPostView];
		
		NSText *fieldEditor = [[aNotification userInfo] objectForKey: @"NSFieldEditor"];
			
		NSString *search = [fieldEditor string];
		
		[self doSearchForString: search];

		[postList reloadData];
	}
}

- (void) doSearchForString: (NSString *) search {
    if (!search || [search isEqualToString: [NSString string]]) {
        [self setCurrentSearch: nil];
		[postList deselectAll: self];
    }
    else {
        [self setCurrentSearch: search];
    }

#ifdef AWOOSTER_CHANGES
	if (useFullTextSearch) {
		[self beginFullTextSearchForQuery: [self currentSearch]];
	}
	else {
		[self setFilteredPosts: [self filterPosts: [self posts] forSearch: [self currentSearch] tags: [self selectedTags]]];
	}
#else
	[self setFilteredPosts: [self filterPosts: [self posts] forSearch: [self currentSearch] tags: [self selectedTags]]];
#endif
}

- (void) makePostListFirstResponder {
	if ([[self filteredPosts] count] > 0) {
		[[NSApp mainWindow] makeFirstResponder: postList];
		[postList selectRow: 0 byExtendingSelection: NO];
	}
}

- (void) makeTagListFirstResponder {
	if ([[self tags] count] > 0) {
		[[NSApp mainWindow] makeFirstResponder: tagList];
		[postList selectRow: 0 byExtendingSelection: NO];
	}	
}

- (void) endTagListEditing {
	NSLog(@"abort editing");
	[tagList abortEditing];
}

- (void) scrollWebViewDown {
	//[webView pageDown: self];
}

- (IBAction) toggleWebPreview: (id) sender {
	if ([webViewBezel superview]) {
		lastPostListBezelFrame = [postListBezel frame];
		[[webViewBezel retain] removeFromSuperview];
		[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: kBLANK_URL]]];
	}
	else {
		[previewSplitView addSubview: [webViewBezel autorelease]];
		[postListBezel setFrameSize: lastPostListBezelFrame.size];
		[previewSplitView adjustSubviews];
		[self previewSelectedLinks];
	}
}

- (void) splitView: (NSSplitView *) sender resizeSubviewsWithOldSize: (NSSize) oldSize {
	[previewSplitView adjustSubviews];
}

- (IBAction) setSearchTypeToBasic: (id) sender {
	[[searchMenu itemWithTag: 0] setState: NSOnState];
	[[searchMenu itemWithTag: 1] setState: NSOffState];
	[[searchMenu itemWithTag: 2] setState: NSOffState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = NO;
    useFullTextSearch = NO;

	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
}

- (IBAction) setSearchTypeToExtended: (id) sender {
	[[searchMenu itemWithTag: 0] setState: NSOffState];
	[[searchMenu itemWithTag: 1] setState: NSOnState];
	[[searchMenu itemWithTag: 2] setState: NSOffState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = YES;
    useFullTextSearch = NO;
	
	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
}

#pragma mark Full Text Search
#ifdef AWOOSTER_CHANGES
- (IBAction) setSearchTypeToFullText: (id) sender 
{
	[[searchMenu itemWithTag: 0] setState: NSOffState];
	[[searchMenu itemWithTag: 1] setState: NSOffState];
	[[searchMenu itemWithTag: 2] setState: NSOnState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = NO;
    useFullTextSearch = YES;
	
	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
}

- (void) beginFullTextSearchForQuery: (NSString *) query {
    if (!query) {
		return;
	}
        
	NSDictionary *searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
		self, @"anObject",
		NSStringFromSelector(@selector(updatePostFilter:)), @"aSelector",
		query, @"query",
		[self posts], @"urlArray",
		nil];
			
	[NSThread detachNewThreadSelector:@selector(search:)
		toTarget:textIndex
		withObject:searchDict];
							   
	[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) 
                                      withObject: self waitUntilDone: NO];
}

- (IBAction) indexAll: (id) sender
{
    NSEnumerator *postEnum = [[self posts] objectEnumerator];
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

- (IBAction) indexSelected: (id) sender
{
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

#endif

- (IBAction) openSelected: (id) sender {
    int selectedRow = [postList selectedRow];
    
    NSArray *postArray = [self filteredPosts];
    
    if (selectedRow > -1 && selectedRow < [postArray count]) {
        DCAPIPost *post = [postArray objectAtIndex: selectedRow];
		
		LSLaunchURLSpec openURLSpec;
		openURLSpec.appURL = NULL;
		openURLSpec.passThruParams = NULL;
		openURLSpec.asyncRefCon = NULL;
		openURLSpec.launchFlags = NULL;
		
		BOOL openInBG = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kOPEN_URLS_IN_BACKGROUND_DEFAULTS_KEY] boolValue];
		unsigned int alternatePressed = [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask;
		
		if (openInBG && !alternatePressed || !openInBG && alternatePressed) {
			openURLSpec.launchFlags = kLSLaunchDontSwitch;
		}
		else {
			openURLSpec.launchFlags = NULL;
		}
		
		openURLSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObjects: [post URL], nil];
		
		LSOpenFromURLSpec(&openURLSpec, NULL);
    }
}

- (int) numberOfRowsInTableView: (NSTableView *) view {
    int count = 0;
    
    if (view == postList) {
        count = [[self filteredPosts] count];
    }
    else if (view == tagList) {
        count = [[self tags] count] + 1;
    }
    
    return count;
}

- (id) tableView: (NSTableView *) view objectValueForTableColumn: (NSTableColumn *) col row: (int) row {
	if (view == postList) {
        DCAPIPost *post = [[self filteredPosts] objectAtIndex: row];
        NSString *identifier = [col identifier];
        
        if (post) {
            id value = [post valueForKey: identifier];
            return value;
        }
    }
    else if (view == tagList) {
        if (row == 0) {
			return [NSString stringWithFormat: NSLocalizedString(@"All (%d Tags)", @"Text for 'all tags' option in tag list"), [[self tags] count]];
        }
        
        return [[self tags] objectAtIndex: row - 1];
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
		DCAPITag *tag = [[self tags] objectAtIndex: row - 1];
		NSString *originalName = [tag name];
		
		if (![originalName isEqualToString: [object name]]) {
			[tag setName: [object name]];
			
			// UPLOAD TAG RENAME HERE
			[[self client] renameTag: originalName to: [object name]];
			[NSThread detachNewThreadSelector: @selector(refreshView) toTarget: self withObject: nil];
		}
	}
}

- (BOOL) tableView: (NSTableView *) tableView writeRows: (NSArray *) rows toPasteboard: (NSPasteboard *) pboard {
	if (tableView == postList) {
		[pboard declareTypes: [NSArray arrayWithObjects: kDCAPIPostPboardType, NSURLPboardType, NSStringPboardType, nil] owner: self];
		
		NSNumber *currentPostIndex = [rows objectAtIndex: 0];
		DCAPIPost *currentPost = [[self filteredPosts] objectAtIndex: [currentPostIndex unsignedIntValue]];
		[pboard setData: [NSKeyedArchiver archivedDataWithRootObject: currentPost] forType: kDCAPIPostPboardType];
		
		NSURL *currentURL = [currentPost URL];
		[pboard setString: [currentURL absoluteString] forType: NSStringPboardType];
		[currentURL writeToPasteboard: pboard];
			
		return YES;
	}
	
	return NO;
}

- (NSDragOperation) tableView: (NSTableView *) tableView validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) operation {
	if (tableView == tagList && postList == [info draggingSource] && operation == NSTableViewDropOn && row > 0 && row <= [[self tags] count]) {
		return NSDragOperationLink;
	}
	
	return NSDragOperationNone;
}

- (BOOL) tableView: (NSTableView *) tableView acceptDrop: (id <NSDraggingInfo>) info row: (int) row dropOperation: (NSTableViewDropOperation) operation {
#warning modify if tableView:validateDrop:proposedRow:proposedOperation returns for more than just tag assignment
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType: kDCAPIPostPboardType];
	
	DCAPIPost *post = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	NSString *postTags = [post tagsAsString];
	postTags = [postTags stringByAppendingFormat: @" %@", [[[self tags] objectAtIndex: row - 1] name]];
	[post setTagsFromString: postTags];
	
	[[self client] addPost: post];
	
	[self refresh: self];
	
	return YES;
	
	return NO;
}


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
	NSArray *tagArray = [self tags];
	
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

	BOOL autologin = [[values valueForKey: kAUTOLOGIN_DEFAULTS_KEY] boolValue];

	if (user) {
		[loginProperties setObject: user forKey: @"username"];

		NSString *password = [SFHFKeychainUtils getWebPasswordForUser: user URL: apiURL domain: kDEFAULT_SECURITY_DOMAIN itemReference: NULL];
		
		if (password) {
			if (autologin) {
				[self loginWithUsername: user password: password APIURL: apiURL];
				return;
			}
			
			[loginProperties setObject: password forKey: @"password"];
		}
	}
	
	[loginProperties setObject: [NSNumber numberWithBool: autologin] forKey: @"autologin"];
	[loginPanel makeKeyAndOrderFront: self];
}

- (IBAction) loginFromPanel: (id) sender {
	[loginController commitEditing];

	NSString *username = [loginProperties objectForKey: @"username"];
	NSString *password = [loginProperties objectForKey: @"password"];
	BOOL autologin = [[loginProperties objectForKey: @"autologin"] boolValue];

	if (!username || !password) {
		return;
	}

    [loginPanel close];

    NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];	
    NSString *apiURLString = [values valueForKey: kAPI_URL_DEFAULTS_KEY];
	NSURL *apiURL = [NSURL URLWithString: apiURLString];	

	/* Write username to defaults */
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setObject: username forKey: kUSERNAME_DEFAULTS_KEY];
	
	/* If we're supposed to autologin, remember that */
	[defaults setObject: [NSNumber numberWithBool: autologin] forKey: kAUTOLOGIN_DEFAULTS_KEY];

	/* Write password to keychain */
	[SFHFKeychainUtils addWebPassword: password forUser: username URL: apiURL domain: kDEFAULT_SECURITY_DOMAIN];
	
	[self loginWithUsername: username password: password APIURL: apiURL];
}

- (void) loginWithUsername: (NSString *) username password: (NSString *) password APIURL: (NSURL *) APIURL {
    DCAPIClient *dcClient = [[DCAPIClient alloc] initWithAPIURL: APIURL username: username password: password delegate: self];
    [self setClient: dcClient];
    [dcClient release];

	[mainWindow makeKeyAndOrderFront: self];
	[mainWindow setTitle: [NSString stringWithFormat: [[NSBundle mainBundle] objectForInfoDictionaryKey: @"DCWindowTitleFormat"], username]];
	[NSThread detachNewThreadSelector: @selector(refreshView) toTarget: self withObject: nil];
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
			[[NSApp mainWindow] makeFirstResponder: postTagsField];
		}
		else if ([currentPostProperties objectForKey: @"description"]) {
			[[NSApp mainWindow] makeFirstResponder: postExtendedField];
		}
		else if ([currentPostProperties objectForKey: @"url"]) {
			[[NSApp mainWindow] makeFirstResponder: postDescriptionField];
		}
		else if (![currentPostProperties objectForKey: @"url"] && pboardContents && [pboardContents hasPrefix: kHTTP_PROTOCOL_PREFIX]) {
			[currentPostProperties setObject: pboardContents forKey: @"url"];
			[[NSApp mainWindow] makeFirstResponder: postDescriptionField];
		}
		else {
			[[NSApp mainWindow] makeFirstResponder: postURLField];
		}
	}

    [NSApp beginSheet: postingInterface modalForWindow: [NSApp mainWindow] modalDelegate: nil didEndSelector: nil contextInfo: nil];

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
    //[self postNewLink: self];
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
	
	[[self client] addPost: newPost];
	
	[self closePostingInterface: self];
	[self refresh: self];
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
		[[self client] deletePostWithURL: [selectedPost URL]];
		[self refresh: self];
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
        [[NSUserDefaultsController sharedUserDefaultsController] save: self];
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
	if (![mainWindow isVisible]) {
		[mainWindow makeKeyAndOrderFront: self];
	}
	
	return NO;
}

- (void) dealloc {
    [client release];
    [tags release];
    [dates release];
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
    [super dealloc];
}

@end
