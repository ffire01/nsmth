//
//  MainMenuViewController.m
//  nsmth
//
//  Created on 13-6-7.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

#import "MainMenuViewController.h"
#import "HotTopicViewController.h"
#import "MainMenuItem.h"

@interface MainMenuViewController ()
@property (nonatomic,strong,readonly) NSFetchedResultsController *frc;
@end

@implementation MainMenuViewController{

}

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
  
  entity = [NSEntityDescription entityForName:kNSMEntityNameMainMenu
                       inManagedObjectContext:[self moc]];
  
  [fetchReq setEntity:entity];
  [fetchReq setSortDescriptors:@[secSortDesc, rowSortDesc]];
  _frc = [[NSFetchedResultsController alloc]
          initWithFetchRequest:fetchReq
          managedObjectContext:[self moc]
          sectionNameKeyPath:kNSMSecSortKey
          cacheName:kNSMEntityNameMainMenu];
  
  [_frc setDelegate:self];
  return _frc;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setTitle:kNSMMainMenuViewTitle];
  [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:kNSMMainMenuCellID];

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

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNSMMainMenuCellID
                                                          forIndexPath:indexPath];
  MainMenuItem *mmItem = [[self frc] objectAtIndexPath:indexPath];
  [[cell textLabel] setText:[mmItem title]];
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([indexPath row] == 0) {
    HotTopicViewController *htVC = [[HotTopicViewController alloc] init];
    [htVC setMoc:[self moc]];
    [[self navigationController] pushViewController:htVC animated:YES];
  }
}

#pragma mark - Fetched results controller delegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  [super controller:(NSFetchedResultsController *)controller
    didChangeObject:(id)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath];
  
  if (type == NSFetchedResultsChangeUpdate)
  {
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
    MainMenuItem *mmItem = [[self frc] objectAtIndexPath:indexPath];
    [[cell textLabel] setText:[mmItem title]];
  }
}

@end
