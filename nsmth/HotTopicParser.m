//
//  HotTopicParser.m
//  nsmth
//
//  Created on 13-6-5.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

#import "HotTopicParser.h"
#import "HotTopic.h"

// all class attribute value that we concerned
#define kRTable  @"RecommendTable"
#define kRTitle  @"RecommendTitle"
#define kRLink   @"RecommendLink"
#define kHTable  @"HotTable"
#define kHTitle  @"HotTitle"
#define kHAuthor @"HotAuthor"
#define kSName   @"SectionName"
#define kSItem   @"SectionItem"
#define kSLine   @"SecLine"
//#define kSTable  @"SecTable"

/*
 check in starElement
 begin constructing section: kRTable, kHTable, kSName
 begin constructing row: kRTitle, kHTitle, kSItem
 set isFirstA: kRLink, kHTitle, kSItem
 
 check in endElement
 end constructing section: kRTable, kHTable, kSLine
 end constructing row: kRLink, kHAuthor, kSItem
 unset isFirstA: when InAnchor and isFirstA is set before
 */

enum {
  IsFirstA  = (1U << 0),
  InAnchor  = (1U << 1),
  InRTable  = (1U << 2),
  InRTitle  = (1U << 3),
  InRLink   = (1U << 4),
  InHTable  = (1U << 5),
  InHTitle  = (1U << 6),
  InHAuthor = (1U << 7),
  InSItem   = (1U << 8),
  InSName   = (1U << 9),
  InSLine   = (1U << 10)
};

typedef NSUInteger state_flags;

@implementation HotTopicParser{
  state_flags _flags;
  // default enconding
  NSStringEncoding _enc;
  NSManagedObjectContext *_moc;
  HotTopic *_workingHT;
  int _workingSecRank;
  NSString *_workingSecName;
  NSString *_workingRowBoard;
  NSString *_workingRowAuthor;
}

- (id)initWithMOC:(NSManagedObjectContext *)moc
{
  self = [super init];
  if (self != nil) {
    assert(moc != nil);
    //GBK:kCFStringEncodingGB_18030_2000
    _enc = NSUTF8StringEncoding;
    _flags = 0U;
    _moc = moc;
    _workingSecRank = 0;
    _workingSecName = nil;
    _workingRowBoard = nil;
    _workingRowAuthor = nil;
  }
  return self;
}

- (void)deleteCachedData
{
  NSFetchRequest *hotTopics = [[NSFetchRequest alloc] init];
  NSError *err = nil;
  NSArray *htArr = nil;
  
  [hotTopics setEntity:[NSEntityDescription entityForName:kNSMEntityNameHotTopic
                                   inManagedObjectContext:_moc]];
  //only fetch the managedObjectID
  [hotTopics setIncludesPropertyValues:NO];
  htArr = [_moc executeFetchRequest:hotTopics error:&err];
  
  assert(htArr != nil);
  for (HotTopic *ht in htArr) {
    [_moc deleteObject:ht];
  }
  
//  err = nil;
//  if (![_moc save:&err]) {
//    NSLog(@"Error while saving\n%@", [err localizedDescription]);
//    abort();
//  };
}

- (void)parser:(DLParser *)parser
  startElement:(const xmlChar *)name
    attributes:(const xmlChar **)attrs
{
  size_t i;
  NSString *value = nil;
  
  if (attrs != NULL) {
    i = 0;
    while (attrs[i] != NULL) {
      if (strncmp((const char*)attrs[i], "class", sizeof("class")) == 0) {
        value = [NSString stringWithCString:(const char*)attrs[i+1]
                                   encoding:_enc];
        if ([value isEqualToString:kRTable]) {
          _flags |= InRTable;
          _workingSecRank = 2 + 10;
          _workingSecName = [NSString stringWithFormat:@"%d%@",_workingSecRank,kNSMHotTopicSec2];
        } else if ([value isEqualToString:kRTitle]) {
          _flags |= InRTitle;
          _workingHT = [NSEntityDescription insertNewObjectForEntityForName:kNSMEntityNameHotTopic
                                                       inManagedObjectContext:_moc];
        } else if ([value isEqualToString:kRLink]) {
          _flags |= InRLink | IsFirstA;
        } else if ([value isEqualToString:kHTable]) {
          _flags |= InHTable;
          _workingSecRank = 1 + 10;
          _workingSecName = [NSString stringWithFormat:@"%d%@",_workingSecRank,kNSMHotTopicSec1];
        } else if ([value isEqualToString:kHTitle]) {
          _flags |= InHTitle | IsFirstA;
          _workingHT = [NSEntityDescription insertNewObjectForEntityForName:kNSMEntityNameHotTopic
                                                     inManagedObjectContext:_moc];
        } else if ([value isEqualToString:kHAuthor]) {
          _flags |= InHAuthor;
        } else if ([value isEqualToString:kSName]) {
          _flags |= InSName;
          if (_workingSecRank == (1 + 10)) {
            _workingSecRank = 2 + 10;
          }
          _workingSecRank++;
        } else if ([value isEqualToString:kSItem]) {
          _flags |= InSItem | IsFirstA;
          _workingHT = [NSEntityDescription insertNewObjectForEntityForName:kNSMEntityNameHotTopic
                                                     inManagedObjectContext:_moc];
        } else if ([value isEqualToString:kSLine]) {
          _flags |= InSLine;
        }
      } else if (strncmp((const char*)attrs[i], "href", sizeof("href")) == 0) {
        if (strncmp((const char *)name, "a", sizeof("a")) == 0) {
          _flags |= InAnchor;
          
          if ((_flags & IsFirstA) == 0) {
            // found thread link
            value = [NSString stringWithCString:(const char*)attrs[i+1]
                                       encoding:_enc];
            if ((_flags & InRLink) == InRLink) {
              [_workingHT setLink:value];
            } else if ((_flags & InHTitle) == InHTitle) {
              [_workingHT setLink:value];
            } else if ((_flags & InSItem) == InSItem) {
              [_workingHT setLink:value];
            }
          }
        }
      }
      i = i + 2;
    }
  }
}

- (void)parser:(DLParser *)parser endElement:(const xmlChar *)name
{
  if ((_flags & InAnchor) == InAnchor) {
    _flags ^= InAnchor;
    if ((_flags & IsFirstA) == IsFirstA) {
      _flags ^= IsFirstA;
    }
  }
  
  NSString *eName = [NSString stringWithCString:(const char*)name
                                       encoding:_enc];
  
  if ([eName isEqualToString:@"td"]) {
    if ((_flags & InRTitle) == InRTitle) {
      _flags ^= InRTitle;
      return;
    }
    
    if ((_flags & InHTitle) == InHTitle) {
      _flags ^= InHTitle;
      return;
    }
    
    if ((_flags & InSLine) == InSLine) {
      _flags ^= InSLine;
      return;
    }
    
    if ((_flags & InRLink) == InRLink) {
      _flags ^= InRLink;
      [_workingHT setSecName:_workingSecName];
      NSString *subtitle = [NSString stringWithFormat:@"[%@]",_workingRowBoard];
      [_workingHT setSubTitle:subtitle];
//      _workingHT = nil;
      return;
    }
    
    if ((_flags & InHAuthor) == InHAuthor) {
      _flags ^= InHAuthor;
      [_workingHT setSecName:_workingSecName];
      NSString *subtitle = [NSString stringWithFormat:@"[%@] By:%@",_workingRowBoard,_workingRowAuthor];
      [_workingHT setSubTitle:subtitle];
//      _workingHT = nil;
      return;
    }
    
    if ((_flags & InSItem) == InSItem) {
      _flags ^= InSItem;
      [_workingHT setSecName:_workingSecName];
      NSString *subtitle = [NSString stringWithFormat:@"[%@]",_workingRowBoard];
      [_workingHT setSubTitle:subtitle];
//      _workingHT = nil;
      return;
    }
  }
  
  if ([eName isEqualToString:@"table"] && (_flags & InRTable) == InRTable) {
    _flags ^= InRTable;
    return;
  }
  
  if ([eName isEqualToString:@"table"] && (_flags & InHTable) == InHTable) {
    _flags ^= InHTable;
    return;
  }
  
  if ([eName isEqualToString:@"span"] && (_flags & InSName) == InSName) {
    _flags ^= InSName;
    return;
  }
}

- (void)parser:(DLParser *)parser foundChars:(const xmlChar *)ch length:(int)len
{
  if ((_flags & InAnchor) == InAnchor) {
    NSString *str = [[NSString alloc] initWithBytes:(const void*)ch
                                             length:len
                                           encoding:_enc];

    if ((_flags & InRTitle) == InRTitle ||
        ((_flags & IsFirstA) == 0 &&
         ((_flags & InHTitle) == InHTitle || (_flags & InSItem) == InSItem))) {
          NSString *title = [str stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
          [_workingHT setTitle:title];
          return;
        }
    
    if ((_flags & IsFirstA) == IsFirstA &&
        ((_flags & InRLink) == InRLink || (_flags & InHTitle) == InHTitle ||
         (_flags & InSItem) == InSItem)) {
          _workingRowBoard = str;
          return;
        }
    
    if ((_flags & InSName) == InSName) {
      _workingSecName = [NSString stringWithFormat:@"%d%@",_workingSecRank,str];
      return;
    }
    
    if ((_flags & InHAuthor) == InHAuthor) {
      _workingRowAuthor = str;
      return;
    }
  }
}

@end
