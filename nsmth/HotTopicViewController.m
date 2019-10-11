//
//  HotTopicViewController.m
//  nsmth
//
//  Created on 13-6-7.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

#import "HotTopicViewController.h"
#import "HotTopicCell.h"
#import "DLParser.h"
#import "HotTopicParser.h"
#import "HotTopic.h"

@interface HotTopicViewController ()<DataDelegate>
@property (nonatomic,strong) NSFetchedResultsController *frc;
@end

@implementation HotTopicViewController

@synthesize frc=_frc;

//- (id)initWithStyle:(UITableViewStyle)style
//{
//  self = [super initWithStyle:style];
//  if (self) {
//  }
//  return self;
//}

- (NSFetchedResultsController *)frc
{
  if (_frc != nil) {
    return _frc;
  }
  
  NSFetchRequest *fetchReq = [[NSFetchRequest alloc] init];
  NSSortDescriptor *rowSortDesc = [[NSSortDescriptor alloc]
                                   initWithKey:kNSMRowSortKey
                                   ascending:YES];
  NSSortDescriptor *secSortDesc = [[NSSortDescriptor alloc]
                                   initWithKey:kNSMSecSortKey
                                   ascending:YES];
  NSEntityDescription *entity = nil;
  
  entity = [NSEntityDescription entityForName:kNSMEntityNameHotTopic
                       inManagedObjectContext:[self moc]];
  
  [fetchReq setFetchBatchSize:10U];
  [fetchReq setEntity:entity];
  [fetchReq setSortDescriptors:@[secSortDesc, rowSortDesc]];
  _frc = [[NSFetchedResultsController alloc]
          initWithFetchRequest:fetchReq
          managedObjectContext:[self moc]
          sectionNameKeyPath:kNSMSecSortKey
          cacheName:nil];
  
  [_frc setDelegate:self];
  return _frc;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self setTitle:kNSMHotTopicViewTitle];
  UIBarButtonItem *refresh_btn =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                target:self
                                                action:@selector(refresh)];
  [[self navigationItem] setRightBarButtonItem:refresh_btn];
  [[self tableView] registerClass:[HotTopicCell class] forCellReuseIdentifier:kNSMHotTopicCellID];
  NSError *err = nil;
  if (![[self frc] performFetch:&err]) {
    NSLog(@"fetch:%@\n%@",[err localizedDescription],[err userInfo]);
    abort();
  }
}

//- (void)didReceiveMemoryWarning
//{
//  [super didReceiveMemoryWarning];
//  // Dispose of any resources that can be recreated.
//}

- (void)refresh
{
  [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    HotTopicParser *htParser = [[HotTopicParser alloc] initWithMOC:[self moc]];
    [htParser deleteCachedData];
    DLParser *dlParser = [[DLParser alloc]
                          initWithURL:kNSMHotTopicURL
                          parserDelegate:htParser
                          dataDelegate:self
                          saveFileName:nil];
    [dlParser start];
  });
}

#pragma mark - Parser data delegate
- (void)didFailWithError:(NSError *)err
{
  [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
}

- (void)didFinished
{
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  
  dispatch_async(queue, ^{
    NSError *err = nil;

    if (![[self moc] save:&err]) {
      NSLog(@"Error while saving\n%@", [err localizedDescription]);
      abort();
    }
  });
  [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
}

#pragma mark - Table view data source delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNSMHotTopicCellID
                                                          forIndexPath:indexPath];
  HotTopic *ht = [[self frc] objectAtIndexPath:indexPath];
  [[cell textLabel] setText:[ht title]];
  [[cell detailTextLabel] setText:[ht subTitle]];
  return cell;
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//}

@end
