//
//  HotTopicParser.h
//  nsmth
//
//  Created on 13-6-5.
//  Copyright (c) 2013年 ffire. All rights reserved.
//
#import "DLParser.h"

@interface HotTopicParser : NSObject<ParserDelegate>
- (id)initWithMOC:(NSManagedObjectContext *)moc;
- (void)deleteCachedData;
@end
