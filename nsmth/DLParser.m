//
//  NSMTHParseOperation.m
//  nsmth
//
//  Created on 13-6-2.
//  Copyright (c) 2013年 ffire. All rights reserved.
//
#import <libxml/encoding.h>
#import <libxml/HTMLParser.h>
#import <iconv.h>
#import "DLParser.h"

int gbk2utf8(unsigned char *out,
             int *outlen,
             const unsigned char *in,
             int *inlen);

int utf82gbk(unsigned char *out,
             int *outlen,
             const unsigned char *in,
             int *inlen);

static void _startElement(void *ctx,
                          const xmlChar *name,
                          const xmlChar **attrs);

static void _endElement(void *ctx,
                        const xmlChar *name);

static void _characters(void *ctx,
                        const xmlChar *ch,
                        int len);

static htmlSAXHandler _htmlSAXHandler = {
  .initialized = XML_SAX2_MAGIC,
  .startElement = _startElement,
  .endElement = _endElement,
  .characters = _characters
};

static void _startElement(void *ctx,
                          const xmlChar *name,
                          const xmlChar **attrs)
{
  DLParser *parser = (__bridge DLParser *)ctx;
  assert([parser isKindOfClass:[DLParser class]]);
  
  [[parser parserDelegate] parser:parser
                     startElement:name
                       attributes:attrs];
}

static void _endElement (void *ctx,
                         const xmlChar *name)
{
  DLParser * parser = (__bridge DLParser *)ctx;
  assert([parser isKindOfClass:[DLParser class]]);
  
  [[parser parserDelegate] parser:parser endElement:name];
}

static void _characters(void *ctx,
                        const xmlChar *ch,
                        int len)
{
  DLParser * parser = (__bridge DLParser *)ctx;
  assert([parser isKindOfClass:[DLParser class]]);
  
  [[parser parserDelegate] parser:parser foundChars:ch length:len];
}


/** xmlCharEncodingInputFunc
 Take a block of chars in the original encoding and
 try to convert it to an UTF-8 block of chars out.
 
 out: a pointer to an array of bytes to store the UTF-8 result
 outlen: the length of @out
 in: a pointer to an array of chars in the original encoding
 inlen:	the length of @in
 Returns: the number of bytes written,
 -1 if lack of space, or
 -2 if the transcoding failed.
 The value of @inlen after return is the number of octets consumed
 if the return value is positive, else unpredictiable.
 The value of @outlen after return is the number of octets consumed.
 */
int gbk2utf8(unsigned char * out,
             int * outlen,
             const unsigned char * in,
             int * inlen)
{
  printf(">gbk2utf8\n");
  assert(*outlen >= 0);
  assert(*inlen >= 0);
  iconv_t iconv_gbk2utf8 = iconv_open("UTF-8", "GBK");
  if (iconv_gbk2utf8 == (iconv_t)(-1)) {
    return -2;
  }
  
  size_t tmp_outlen,tmp_inlen,iconv_rslt;
  tmp_inlen = *inlen;
  tmp_outlen = *outlen;
  
  char *outbuf = (char *)out;
  char *inbuf = (char *)in;
  
  errno = 0;
  iconv_rslt = iconv(iconv_gbk2utf8,
                     &inbuf,
                     &tmp_inlen,
                     &outbuf,
                     &tmp_outlen);
  if (iconv_rslt == (size_t)(-1))
  {
    if (errno == E2BIG) {
      return -1;
    } else {
      return -2;
    }
  }
  *outlen = ((unsigned char *) outbuf - out);
  *inlen = ((unsigned char *) inbuf - in);
  iconv_close(iconv_gbk2utf8);
  return *outlen;
}

/** xmlCharEncodingOutputFunc
 Take a block of UTF-8 chars in and try to convert it to another encoding.
 Note: a first call designed to produce heading info is called with in = NULL.
 If stateful this should also initialize the encoder state.
 
 out: a pointer to an array of bytes to store the result
 outlen: the length of @out
 in: a pointer to an array of UTF-8 chars
 inlen:	the length of @in
 Returns: the number of bytes written,
 -1 if lack of space, or
 -2 if the transcoding failed.
 The value of @inlen after return is the number of octets consumed if
 the return value is positive, else unpredictiable.
 The value of @outlen after return is the number of octets produced.
 */
int utf82gbk(unsigned char *out,
             int *outlen,
             const unsigned char *in,
             int *inlen)
{
  printf(">utf82gbk\n");
  assert(*outlen >= 0);
  assert(*inlen >= 0);
  iconv_t iconv_utf82gbk = iconv_open("GBK", "UTF-8");
  if (iconv_utf82gbk == (iconv_t)(-1)) {
    return -2;
  }
  
  size_t tmp_outlen,tmp_inlen,iconv_rslt;
  tmp_inlen = *inlen;
  tmp_outlen = *outlen;
  
  
  char *outbuf = (char *)out;
  char *inbuf = (char *)in;
  
  errno = 0;
  iconv_rslt = iconv(iconv_utf82gbk,
                     &inbuf,
                     &tmp_inlen,
                     &outbuf,
                     &tmp_outlen);
  
  if (iconv_rslt == (size_t)(-1))
  {
    if (errno == E2BIG) {
      return -1;
    } else {
      return -2;
    }
  }
  
  *outlen = ((unsigned char *) outbuf - out);
  *inlen = ((unsigned char *) inbuf - in);
  iconv_close(iconv_utf82gbk);
  return *outlen;
}

#pragma mark - class difinition
@interface DLParser ()<NSURLConnectionDataDelegate>

@end

@implementation DLParser
{
  // original URL
  NSString * _srcURL;
  // list view type
  int _listType;
  // save-to-disc file name
  NSString * _dstFileName;
  // save-to-disc temp file URL
  NSURL * _tmpFileURL;
  // save-to-disc target file URL
  NSURL * _dstFileURL;
  // for writing temp file
  NSFileHandle * _outFileHandle;
  // connection build for original URL
  NSURLConnection * _conn;
  // html parse context
  htmlParserCtxtPtr _htmlParserCtx;
}

- (id)initWithURL:(NSString *)url
   parserDelegate:(id<ParserDelegate>)pd
     dataDelegate:(id<DataDelegate>)dd
     saveFileName:(NSString *)filename
{
  self = [super init];
  if (self != nil) {
    assert(url != nil && pd != nil && dd != nil);
    
    _srcURL = url;
    _dstFileName = filename;
    [self setParserDelegate:pd];
    [self setDataDelegate:dd];
    _htmlParserCtx = NULL;
  }
  return self;
}

- (void)dealloc
{
  _conn = nil;
  _outFileHandle = nil;
  _parserDelegate = nil;
  _dataDelegate = nil;
  if (_htmlParserCtx) {
    htmlFreeParserCtxt(_htmlParserCtx);
    _htmlParserCtx = NULL;
  }
  xmlCleanupCharEncodingHandlers();
}

- (void)start
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *err = nil;
  if (_dstFileName != nil) {
    _dstFileURL = [fm URLForDirectory:NSDocumentationDirectory
                             inDomain:NSUserDomainMask
                    appropriateForURL:nil
                               create:YES error:&err];
    _dstFileURL = [_dstFileURL URLByAppendingPathComponent:_dstFileName
                                               isDirectory:NO];
    assert(_dstFileURL != nil);
  }
  
  NSURL *url = [[NSURL alloc] initWithString:_srcURL];
  NSURLRequest *req = [[NSURLRequest alloc]
                       initWithURL:url
                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                       timeoutInterval:30.0];
  _conn = [[NSURLConnection alloc] initWithRequest:req
                                          delegate:self
                                  startImmediately:NO];
  assert(_conn != nil);
  [_conn start];
  CFRunLoopRun();
}

- (NSURL *)pathForTmpFileWithPrefix:(NSString *)prefix
{
  NSURL *result = nil;
  CFUUIDRef   uuid = NULL;
  CFStringRef uuidStr = NULL;
  
  if (prefix == nil) {
    prefix = @"NSMTH";
  }
  assert(prefix != nil);
  
  uuid = CFUUIDCreate(NULL);
  assert(uuid != NULL);
  
  uuidStr = CFUUIDCreateString(NULL, uuid);
  assert(uuidStr != NULL);
  
  NSError *err = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  result = [fm URLForDirectory:NSCachesDirectory
                      inDomain:NSUserDomainMask
             appropriateForURL:nil
                        create:YES error:&err];
  assert(result != nil);
  
  result = [result URLByAppendingPathComponent:
            [NSString stringWithFormat:@"%@%@", prefix, uuidStr]];
  assert(result != nil);
  
  CFRelease(uuidStr);
  CFRelease(uuid);
  
  return result;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
//  NSLog(@">didReceiveResponse");
  
  assert(connection == _conn);
  NSHTTPURLResponse *httpres = (NSHTTPURLResponse *)response;
  if ([httpres statusCode] != 200) {
    [connection cancel];
    _conn = nil;
    _outFileHandle = nil;
    return;
  } else {
    // and GB2312 and GBK encoding support
    // treat GB2312 as GBK
    xmlNewCharEncodingHandler("gb2312", gbk2utf8, utf82gbk);
    xmlNewCharEncodingHandler("gbk", gbk2utf8, utf82gbk);
    
    if (_htmlParserCtx) {
      htmlFreeParserCtxt(_htmlParserCtx);
    }
    // create parser context
    _htmlParserCtx = htmlCreatePushParserCtxt(&_htmlSAXHandler,
                                              (__bridge void *)(self),
                                              NULL,
                                              0,
                                              NULL,
                                              XML_CHAR_ENCODING_NONE);
    if (_htmlParserCtx == NULL) {
      //XML_ERR_INTERNAL_ERROR
      NSLog(@"create parser");
      abort();
    } else {
      int err;
      err = htmlCtxtUseOptions(_htmlParserCtx,
                               HTML_PARSE_RECOVER |
                               HTML_PARSE_NOERROR |
                               HTML_PARSE_NOWARNING);
      if (err != 0) {
        (void) htmlCtxtUseOptions(_htmlParserCtx,
                                  HTML_PARSE_NOERROR |
                                  HTML_PARSE_NOWARNING);
      }
    }
    
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (_tmpFileURL != nil) {
      [_outFileHandle closeFile];
      if (![fm removeItemAtURL:_tmpFileURL error:&err]){
        if ([err code] != NSFileNoSuchFileError) {
          NSLog(@"del tmpfile:%@",[err localizedDescription]);
          abort();
        }
      }
      
//      NSLog(@"did del tmpfile:%@",_tmpFileURL);
    }
    
    if (_dstFileURL != nil) {
      err = nil;
      if (![fm removeItemAtURL:_dstFileURL error:&err]){
        if ([err code] != NSFileNoSuchFileError) {
          NSLog(@"del dstfile:%@",[err localizedDescription]);
          abort();
        }
      }
//      NSLog(@"did del dstfile:%@",_dstFileURL);
    }
    
    _tmpFileURL = [self pathForTmpFileWithPrefix:nil];
    if ([fm createFileAtPath:[_tmpFileURL path]
                    contents:nil
                  attributes:nil]) {
      err = nil;
      _outFileHandle = [NSFileHandle
                        fileHandleForWritingToURL:_tmpFileURL
                        error:&err];
      if (err != nil) {
        NSLog(@"create outfilehandle:%@",[err localizedDescription]);
        abort();
      }
    } else {
      NSLog(@"no tmpfile exists");
      abort();
    }
    //        NSString *lenstr = [httpres allHeaderFields][@"Content-length"];
  }
  
  
//  NSLog(@"<didReceiveResponse");
  
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//  NSLog(@">didReceiveData");
  
  assert(connection == _conn);
  int error;
  error = htmlParseChunk(_htmlParserCtx,
                         (const char*)[data bytes],
                         (int)[data length],
                         0);
  //    if (error != 0) {
  //        NSLog(@"lib parse err:%@",error);
  //    }
  [_outFileHandle writeData:data];
  
//  NSLog(@"<didReceiveData:%lu bytes",(unsigned long)[data length]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//  NSLog(@">didFinishLoading");
  
  // terminate parse
  htmlParseChunk(_htmlParserCtx, NULL, 0, 1);
  if (_htmlParserCtx != NULL) {
    htmlFreeParserCtxt(_htmlParserCtx);
    _htmlParserCtx = NULL;
  }
  
  [_outFileHandle closeFile];
  NSFileManager *fm = [NSFileManager defaultManager];
  if (_dstFileURL != nil) {
    NSError *err = nil;
    if(![fm moveItemAtURL:_tmpFileURL toURL:_dstFileURL error:&err]) {
      NSLog(@"mv dstfile:%@",[err localizedDescription]);
    }
  }
  [[self dataDelegate] didFinished];
//  NSLog(@"<didFinishLoading:%@",_srcURL);
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  NSLog(@">didFailWithError:%@",[error localizedDescription]);
  
  if (_htmlParserCtx != NULL) {
    htmlFreeParserCtxt(_htmlParserCtx);
    _htmlParserCtx = NULL;
  }
  
  NSFileManager *fm =[NSFileManager defaultManager];
  if (_tmpFileURL != nil) {
    [_outFileHandle closeFile];
    [fm removeItemAtURL:_tmpFileURL error:nil];
  }
  
  [[self dataDelegate] didFailWithError:error];
//  NSLog(@"<didFailWithError");
  CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
