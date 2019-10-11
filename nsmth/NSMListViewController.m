//
//  NSMTHMainMenuViewController.m
//  nsmth
//
//  Created on 4/21/13.
//  Copyright (c) 2013 ffire. All rights reserved.
//

#import "NSMListViewController.h"
#import "NSMList.h"
#import "DLParser.h"
#import "HotTopicParser.h"

#define kSubTitleFontSize 13.0f
#define kCellContentWidth 320.0f
#define kCellContentMargin 10.0f

@implementation NSMListViewController

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
//  Rotation support for iOS 5.x and earlier, note for iOS 6.0 and later all you
//  need is "UISupportedInterfaceOrientations" defined in your Info.plist.
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
  return (orientation == UIInterfaceOrientationPortrait);
}
#endif

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (_listType == kNSMTHListTypeHotTopic) {
    NSMList *list = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    CGSize titleSize = [[list title]
                        sizeWithFont:[UIFont systemFontOfSize:
                                      [UIFont systemFontSize]]
                        forWidth:(kCellContentWidth - kCellContentMargin * 2)
                        lineBreakMode:NSLineBreakByCharWrapping];
    CGSize subTitleSize = [[list subTitle]
                           sizeWithFont:[UIFont systemFontOfSize:kSubTitleFontSize]
                           forWidth:(kCellContentWidth - kCellContentMargin * 2)
                           lineBreakMode:NSLineBreakByCharWrapping];
    return titleSize.height + subTitleSize.height + 2 * kCellContentMargin;
  } else {
    return [tableView rowHeight];
  }
}

@end
