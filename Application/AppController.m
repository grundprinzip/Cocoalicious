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
	}     
	
	return self;
}

- (void) awakeFromNib {
	NSRect webViewBezelFrame = [[webView superview] frame];
	[webView setFrame: NSInsetRect(webViewBezelFrame, 2, 2)];
	[webView display];

	NSRect postListBezelFrame = [[[postList enclosingScrollView] superview] frame];
	[[postList enclosingScrollView] setFrame: NSMakeRect(postListBezelFrame.origin.x + 2, postListBezelFrame.origin.y + 2, postListBezelFrame.size.width - 4, postListBezelFrame.size.height - 3)];
	
	NSRect tagListBezelFrame = [[[tagList enclosingScrollView] superview] frame];
	[[tagList enclosingScrollView] setFrame: NSMakeRect(tagListBezelFrame.origin.x + 2, tagListBezelFrame.origin.y + 2, tagListBezelFrame.size.width - 4, tagListBezelFrame.size.height - 3)];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	/* Support for NetNewsWire External Weblog Editor Interface */
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler: self andSelector: @selector(postNewNNWLink:withReplyEvent:) forEventClass: DCNNWPostAppleEventClass andEventID: DCNNWPostAppleEventID];

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

	[tagList initializeColumnsUsingHeaderCellClass: [SFHFMetalTableHeaderCell class] formatterClass: [DCAPITagFormatter class]];

    SFHFMetalTableHeaderCell *cornerCell = [[SFHFMetalTableHeaderCell alloc] initTextCell: @" "];
	SFHFCornerView *cornerControl = [[SFHFCornerView alloc] init];
    [cornerControl setCell: cornerCell];
    [tagList setCornerView: cornerControl];
    [cornerControl release];
	[cornerCell release];
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
	[self setTags: [[self client] requestTagsFilteredByDate: nil]];
}

- (void) refreshPostView {
    @synchronized (self) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		[spinnyThing performSelectorOnMainThread: @selector(startAnimation:) withObject: self waitUntilDone: YES];

		[self refreshPosts];
		[postList reloadData];

		[spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: YES];

		[pool release];
	}
}

- (void) refreshPosts {
	DCAPITag *tagFilter = [self currentTagFilter];

	NSArray *unfilteredPosts = [[self client] requestPostsFilteredByTag: tagFilter count: nil];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO selector: @selector(compare:)];
	NSArray *resortedPosts = [unfilteredPosts sortedArrayUsingDescriptors: [NSArray arrayWithObjects: sortDescriptor, nil]];
	
	NSString *search = [self currentSearch];
	[self setPosts: resortedPosts];
	
	if (search) {
		[self setFilteredPosts: [self filterPosts: [self posts] forSearch: search]];
	}
	else {
		[self setFilteredPosts: nil];
	}
}

- (NSArray *) filterPosts: (NSArray *) postArray forSearch: (NSString *) search {
    NSEnumerator *postEnum = [postArray objectEnumerator];
    DCAPIPost *currentPost;
    NSMutableArray *filteredPostList = [[NSMutableArray alloc] init];
	BOOL searchTags = NO;
	BOOL searchURIs = NO;

	if (useExtendedSearch) {
		searchTags = YES;
		searchURIs = YES;
	}

    while ((currentPost = [postEnum nextObject]) != nil) {
		if ([currentPost matchesSearch: search extended: YES tags: searchTags URIs: searchURIs]) {
			[filteredPostList addObject: currentPost];
        }
    }

    return [filteredPostList autorelease];
}

- (void) refreshDates {
	[self setDates: [[self client] requestDatesFilteredByTag: nil]];
}

- (void) refreshAll {
    [self refreshTags];
    [self refreshPosts];
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
        [self setFilteredPosts: [self posts]];
		[postList deselectAll: self];
    }
    else {
        [self setCurrentSearch: search];
        [self setFilteredPosts: [self filterPosts: [self posts] forSearch: search]];
    }
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

- (void) scrollWebViewDown {
	//[webView pageDown: self];
}

- (IBAction) setSearchTypeToBasic: (id) sender {
	[[searchMenu itemWithTag: 0] setState: NSOnState];
	[[searchMenu itemWithTag: 1] setState: NSOffState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = NO;

	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
}

- (IBAction) setSearchTypeToExtended: (id) sender {
	[[searchMenu itemWithTag: 0] setState: NSOffState];
	[[searchMenu itemWithTag: 1] setState: NSOnState];
	
	[[searchField cell] setSearchMenuTemplate: [[searchField cell] searchMenuTemplate]];

	useExtendedSearch = YES;
	
	[self doSearchForString: [searchField stringValue]];
    [postList reloadData];
}

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
			[self resortTags];
			[NSThread detachNewThreadSelector: @selector(refreshPostView) toTarget: self withObject: nil];
		}
	}
}

- (BOOL) tableView: (NSTableView *) tableView writeRows: (NSArray *) rows toPasteboard: (NSPasteboard *) pboard {
	if (tableView == postList) {
		[pboard declareTypes: [NSArray arrayWithObjects: NSURLPboardType, NSStringPboardType, NSFilenamesPboardType, nil] owner: self];
		
		NSNumber *currentPostIndex = [rows objectAtIndex: 0];
		DCAPIPost *currentPost = [[self filteredPosts] objectAtIndex: [currentPostIndex unsignedIntValue]];

		NSURL *currentURL = [currentPost URL];
		[pboard setString: [currentURL absoluteString] forType: NSStringPboardType];
		[currentURL writeToPasteboard: pboard];

		return YES;
	}
	
	return NO;
}

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
    
    int selectedRow = -1;
    
    if (table == tagList) {
		[self setCurrentSearch: nil];
		[searchField setStringValue: [NSString string]];
		[self resetPostView];
		[self updateTagFilterFromSelection];
        [NSThread detachNewThreadSelector: @selector(refreshPostView) toTarget: self withObject: nil];
    }
    else if (table == postList) {
        selectedRow = [postList selectedRow];
        
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
}

- (void) resetPostView {
	[[webView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: kBLANK_URL]]];
	[statusText setStringValue: [NSString string]];
	[postList deselectAll: self];
}

- (void) webView: (WebView *) sender didFinishLoadForFrame: (WebFrame *) frame {
    if (frame == [sender mainFrame]){
		[spinnyThing performSelectorOnMainThread: @selector(stopAnimation:) withObject: self waitUntilDone: YES];
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

- (IBAction) showPostingInterface: (id) sender {
	[NSApp activateIgnoringOtherApps: YES];
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSString *type = [pboard availableTypeFromArray: [NSArray arrayWithObjects: NSURLPboardType, NSStringPboardType, nil]];
	
	if (type) {
		NSString *pboardContents = [pboard stringForType: type];

		if ([currentPostProperties objectForKey: @"url"]) {
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

- (IBAction) togglePreviewPane: (id) sender {

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
	
	DCAPIPost *newPost = [[DCAPIPost alloc] initWithURL: postURL description: postDescription extended: postExtended date: postDate tags: nil hash: nil];
	[newPost setTagsFromString: postTags];
	
	[[self client] addPost: newPost];
	
	[self closePostingInterface: self];
	[self refresh: self];
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
	return YES;
}

- (void) applicationDidResignActive: (NSNotification *) aNotification {
	float alphaValue = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kDEACTIVATE_ALPHA_DEFAULTS_KEY] floatValue];
	[mainWindow setAlphaValue: alphaValue];
}

- (void) applicationDidBecomeActive: (NSNotification *) aNotification {
	[mainWindow setAlphaValue: 1.0];
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
    [super dealloc];
}

@end