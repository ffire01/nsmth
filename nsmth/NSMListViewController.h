//
//  NSMTHMainMenuViewController.h
//  nsmth
//
//  Created on 4/21/13.
//  Copyright (c) 2013 ffire. All rights reserved.
//

@interface NSMListViewController : UITableViewController

@property (nonatomic,strong) NSManagedObjectContext *listMOC;

- (id)initWithListType:(int)listType;

@end
