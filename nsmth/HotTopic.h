//
//  HotTopic.h
//  nsmth
//
//  Created on 13-6-8.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

@interface HotTopic : NSManagedObject

@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSNumber * rank;
@property (nonatomic, retain) NSString * secName;
@property (nonatomic, retain) NSString * subTitle;
@property (nonatomic, retain) NSString * title;

@end
