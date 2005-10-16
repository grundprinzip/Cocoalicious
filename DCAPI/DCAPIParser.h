//
//  DCAPIParser.h
//  Delicious Client
//
//  Created by Buzz Andersen on Wed Jan 28 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCAPIDate.h"
#import "DCAPITag.h"
#import "DCAPIPost.h"
#import "defines.h"
#import "NSString+SFHFUtils.h"


@interface DCAPIParser : NSObject {
    NSXMLParser *parser;
    NSData *XMLData;
    NSMutableArray *posts;
    NSMutableArray *dates;
    NSMutableArray *tags;
	NSCalendarDate *lastUpdate;
}

- initWithXMLData: (NSData *) xml;
- (NSDate *) parseForLastUpdateTime;
- (void) parseForPosts: (NSMutableArray **) postList dates: (NSMutableArray **) dateList tags: (NSMutableArray **) tagList;
- (void) setXMLData: (NSData *) newXMLData;
- (NSData *) XMLData;
- (NSString *) XMLString;

@end
