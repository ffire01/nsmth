//
//  BaseTableViewController.h
//  nsmth
//
//  Created on 13-6-7.
//  Copyright (c) 2013年 ffire. All rights reserved.
//

@interface BaseTableViewController:UITableViewController<NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSManagedObjectContext *moc;

@end
