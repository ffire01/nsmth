//
//  NSMTHAsyncDownloader.h
//  nsmth
//
//  Created on 13-5-21.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

@interface AsyncDownloader : NSObject{
    // the number of bytes that need to be downloaded
    long long downloadSize;
    // the total amount downloaded thus far
    long long totalDownloaded;
}

// original URL to download.
@property (nonatomic,strong) NSString *srcURL;

@property (nonatomic,strong) NSString *dstFileName;


- (void)startDownload;
@end
