//
//  DCAPIParser.m
//  Delicious Client
//
//  Created by Buzz Andersen on Wed Jan 28 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import "DCAPIParser.h"

/* static NSString *kPOST_LIST_ELEMENT = @"posts"; */
static NSString *kPOST_ELEMENT = @"post";
static NSString *kPOST_HREF_ATTRIBUTE = @"href";
static NSString *kPOST_DESCRIPTION_ATTRIBUTE = @"description";
static NSString *kPOST_EXTENDED_ATTRIBUTE = @"extended";
static NSString *kPOST_DATE_ATTRIBUTE = @"time";
static NSString *kPOST_TAGS_ATTRIBUTE = @"tag";

/* static NSString *kDATE_LIST_ELEMENT = @"dates"; */
static NSString *kDATE_ELEMENT = @"date";
static NSString *kDATE_ATTRIBUTE = @"date";
static NSString *kDATE_COUNT_ATTRIBUTE = @"count";

/* static NSString *kTAG_LIST_ELEMENT = @"tags"; */
static NSString *kTAG_ELEMENT = @"tag";
static NSString *kTAG_ATTRIBUTE = @"tag";
static NSString *kTAG_COUNT_ATTRIBUTE = @"count";
static NSString *kPOST_HASH_ATTRIBUTE = @"hash";


@implementation DCAPIParser

- initWithXMLData: (NSData *) xml {
    [super init];
    
    [self setXMLData: xml];
    
    parser = [[NSXMLParser alloc] initWithData: xml];
    [parser setDelegate: self];
    [parser setShouldResolveExternalEntities: YES];
    
    return self;
}

- (void) parseForPosts: (NSMutableArray **) postList dates: (NSMutableArray **) dateList tags: (NSMutableArray **) tagList {
    if (!parser || !XMLData) {
        return;
    }
    
    if (postList) {
        posts = *postList;
    }
    else {
        posts = nil;
    }
    
    if (dateList) {
        dates = *dateList;
    }
    else {
        dates = nil;
    }
    
    if (tagList) {
        tags = *tagList;
    }
    else {
        tags = nil;
    }
    
    [parser parse];
}

- (void) setXMLData: (NSData *) newXMLData {
    if (XMLData != newXMLData) {
        [XMLData release];
        XMLData = [newXMLData copy];
    }
}

- (NSData *) XMLData {
    return [[XMLData retain] autorelease];
}

- (NSString *) XMLString {
    NSString *string = [[NSString alloc] initWithData: XMLData encoding: NSUnicodeStringEncoding];
    return [string autorelease];
}

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qualifiedName attributes: (NSDictionary *) attributeDict {
    if (posts && [elementName isEqualToString: kPOST_ELEMENT]) {
        NSString *URLString = [attributeDict objectForKey: kPOST_HREF_ATTRIBUTE];
        NSURL *postURL = [NSURL URLWithString: [URLString stringByUnescapingEntities: nil]];
        
        NSString *postDescription = [[attributeDict objectForKey: kPOST_DESCRIPTION_ATTRIBUTE] stringByUnescapingEntities: nil];
        NSString *postExtended = [[attributeDict objectForKey: kPOST_EXTENDED_ATTRIBUTE] stringByUnescapingEntities: nil];
        
        NSString *postDateString = [[[attributeDict objectForKey: kPOST_DATE_ATTRIBUTE] stringByUnescapingEntities: nil] stringByAppendingString: kDEFAULT_TIME_ZONE_NAME];
        NSCalendarDate *postDate = [NSCalendarDate dateWithString: postDateString calendarFormat: kDEFAULT_DATE_TIME_FORMAT];
	
		NSString *tagString = [[attributeDict objectForKey: kPOST_TAGS_ATTRIBUTE] stringByUnescapingEntities: nil];
		
		NSLog(@"tagString: %@", tagString);

		NSString *hashString = [[attributeDict objectForKey: kPOST_HASH_ATTRIBUTE] stringByUnescapingEntities: nil];
	
        DCAPIPost *post = [[DCAPIPost alloc] initWithURL: postURL description: postDescription extended: postExtended date: postDate tags: nil urlHash: hashString];
		[post setTagsFromString: tagString];
        
        [posts addObject: post];
        [post release];
    }
    else if (dates && [elementName isEqualToString: kDATE_ELEMENT]) {
        NSString *dateString = [[attributeDict objectForKey: kDATE_ATTRIBUTE] stringByUnescapingEntities: nil];
        
        if (dateString) {
            NSCalendarDate *rawDate = [NSCalendarDate dateWithString: dateString calendarFormat: kDEFAULT_DATE_FORMAT];
            
            NSNumber *count = [attributeDict objectForKey: kDATE_COUNT_ATTRIBUTE];
            
            DCAPIDate *date = [[DCAPIDate alloc] initWithDate: rawDate count: count];
                        
            [dates addObject: date];
            [date release];
        }
    }
    else if (tags && [elementName isEqualToString: kTAG_ELEMENT]) {
        NSString *tagString = [[attributeDict objectForKey: kTAG_ATTRIBUTE] stringByUnescapingEntities: nil];
		
		NSLog(@"tag: %@", tagString);
        
        if (tagString) {
            NSNumber *count = [attributeDict objectForKey: kTAG_COUNT_ATTRIBUTE];
            
            DCAPITag *tag = [[DCAPITag alloc] initWithName: tagString count: count];
            [tags addObject: tag];
            [tag release];
        }
    }
}

- (NSData *)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)name systemID:(NSString *)systemID {
    NSLog(@"EXTERNAL ENTITY: %@",name);
	return nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"PARSE ERROR: %@", parseError);
}

- (void) dealloc {
    [XMLData release];
    [parser release];
    [super dealloc];
}

@end
