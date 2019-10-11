//
//  NSMTHAsyncDownloader.m
//  nsmth
//
//  Created on 13-5-21.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

#import "AsyncDownloader.h"

@interface AsyncDownloader ()<NSURLConnectionDataDelegate>

@property (nonatomic,strong) NSFileHandle *outFileHandle;

// connection build for original URL
@property (nonatomic,strong) NSURLConnection *conn;

@end

@implementation AsyncDownloader{
    NSURL *tmpFileURL;
    NSURL *dstFileURL;
}

- (void)startDownload
{
#ifndef NDEBUG
    NSLog(@">startDownload\n%@", [self srcURL]);
#endif
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    dstFileURL = [fm URLForDirectory:NSDocumentationDirectory
                            inDomain:NSUserDomainMask
                   appropriateForURL:nil
                              create:YES error:&err];
    assert(dstFileURL != nil);
    dstFileURL = [dstFileURL URLByAppendingPathComponent:[self dstFileName]
                                             isDirectory:NO];
    assert(dstFileURL != nil);
    
    NSURL *url = [[NSURL alloc] initWithString:[self srcURL]];
    NSURLRequest *req = [[NSURLRequest alloc]
                         initWithURL:url
                         cachePolicy:NSURLRequestReloadRevalidatingCacheData
                         timeoutInterval:30.0];
    [self setConn:[[NSURLConnection alloc] initWithRequest:req
                                                  delegate:self
                                          startImmediately:NO]];
    [[self conn] start];
    
    CFRunLoopRun();
#ifndef NDEBUG
    NSLog(@"<startDownload\n");
#endif
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

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
#ifndef NDEBUG
    NSLog(@">didReceiveResponse");
#endif
    
    assert(connection == [self conn]);
    NSHTTPURLResponse *httpres = (NSHTTPURLResponse *)response;
    if ([httpres statusCode] != 200) {
        [connection cancel];
        [self setConn:nil];
        [self setOutFileHandle:nil];
        return;
    } else {
        NSError *err = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if (tmpFileURL != nil) {
            [[self outFileHandle] closeFile];
            [fm removeItemAtURL:tmpFileURL error:&err];
            if (err != nil && [err code] != NSFileNoSuchFileError) {
                NSLog(@"-didReceiveResponse:remove err\n%@",
                      [err localizedDescription]);
                abort();
            }
#ifndef NDEBUG
            NSLog(@"-didReceiveResponse:remove\n%@",tmpFileURL);
#endif
        }
        
        err = nil;
        [fm removeItemAtURL:dstFileURL error:&err];
        if (err != nil && [err code] != NSFileNoSuchFileError) {
            NSLog(@"-didReceiveResponse:remove err\n%@",
                  [err localizedDescription]);
            abort();
        }
        tmpFileURL = [self pathForTmpFileWithPrefix:nil];
        [fm createFileAtPath:[tmpFileURL path] contents:nil attributes:nil];
        err = nil;
        [self setOutFileHandle:[NSFileHandle
                                fileHandleForWritingToURL:tmpFileURL
                                error:&err]];
        if (err != nil) {
            NSLog(@"-didReceiveResponse:writing file handle err\n%@",
                  [err localizedDescription]);
            abort();
        }
        NSString *lenstr = [httpres allHeaderFields][@"Content-length"];
        downloadSize = [lenstr longLongValue];
        totalDownloaded = 0L;
    }
    
#ifndef NDEBUG
    NSLog(@"<didReceiveResponse");
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#ifndef NDEBUG
    NSLog(@">didReceiveData");
#endif
    
    assert(connection == [self conn]);
    totalDownloaded = totalDownloaded + [data length];
    [[self outFileHandle] writeData:data];
    
#ifndef NDEBUG
    NSLog(@"<didReceiveData\n%u",[data length]);
#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#ifndef NDEBUG
    NSLog(@">didFinishLoading");
#endif
    
    [[self outFileHandle] closeFile];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    [fm moveItemAtURL:tmpFileURL toURL:dstFileURL error:&err];
    
#ifndef NDEBUG
    NSLog(@"<didFinishLoading\n%@",[self srcURL]);
#endif
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifndef NDEBUG
    NSLog(@"fail with error\n%@",[error localizedDescription]);
#endif
    
    NSFileManager *fm =[NSFileManager defaultManager];
    if (tmpFileURL != nil) {
        [[self outFileHandle] closeFile];
        NSError *err = nil;
        [fm removeItemAtURL:tmpFileURL error:&err];
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

//- (BOOL)connection:(NSURLConnection *)connection
//canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
//{
//    assert(connection == [self conn]);
//    return [[protectionSpace authenticationMethod]
//            isEqualToString:NSURLAuthenticationMethodServerTrust];
//}

@end
