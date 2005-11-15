//
//  NSString+SFHFUtils.h
//  Delicious Client
//
//  Created by Buzz Andersen on Fri May 14 2004.
//  Copyright (c) 2004 Sci-Fi Hi-Fi. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (SFHFUtils) 

- (NSString *) stringByUnescapingEntities: (NSDictionary *) entitiesDictionary;
- (NSString *) stringByAddingPercentEscapesUsingEncoding: (NSStringEncoding) encoding legalURLCharactersToBeEscaped: (NSString *) legalCharacters;
- (NSString *) stringByReplacingPercentEscapes;

@end
