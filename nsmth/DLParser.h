//
//  NSMTHParseOperation.h
//  nsmth
//
//  Created on 13-6-2.
//  Copyright (c) 2013年 ffire. All rights reserved.
//
#import <libxml/xmlstring.h>

@protocol ParserDelegate;
@protocol DataDelegate;

@interface DLParser : NSObject

@property (nonatomic,weak) id<ParserDelegate> parserDelegate;
@property (nonatomic,weak) id<DataDelegate> dataDelegate;

- (id)initWithURL:(NSString *)url
   parserDelegate:(id<ParserDelegate>)pd
     dataDelegate:(id<DataDelegate>)dd
     saveFileName:(NSString *)filename;

- (void)start;
@end

@protocol ParserDelegate

- (void)parser:(DLParser *)parser
  startElement:(const xmlChar *)name
    attributes:(const xmlChar **)attrs;

- (void)parser:(DLParser *)parser
    endElement:(const xmlChar *)name;

- (void)parser:(DLParser *)parser
    foundChars:(const xmlChar *)ch
        length:(int)len;

@end

@protocol DataDelegate

- (void)didFinished;
- (void)didFailWithError:(NSError *)err;

@end
