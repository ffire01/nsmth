//
//  NSMTHAppDelegate.m
//  nsmth
//
//  Created on 4/21/13.
//  Copyright (c) 2013 ffire. All rights reserved.
//

#import "AppDelegate.h"
#import "NSMNavigationController.h"
#import "MainMenuViewController.h"

@interface AppDelegate()

@property (nonatomic,strong,readonly) NSManagedObjectContext *moc;
@property (nonatomic,strong,readonly) NSManagedObjectModel *mom;
@property (nonatomic,strong,readonly) NSPersistentStoreCoordinator *psc;

- (void)saveContext;
@end

@implementation AppDelegate

@synthesize moc=_moc,mom=_mom,psc=_psc;

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
  MainMenuViewController *mmc = [[MainMenuViewController alloc] init];
  NSMNavigationController *navc = [[NSMNavigationController alloc]
                                   initWithRootViewController:mmc];
  
  [mmc setMoc:[self moc]];
  [[self window] setRootViewController:navc];
  [[self window] setBackgroundColor:[UIColor whiteColor]];
  [[self window] makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [self saveContext];
}

/*
- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}
*/

- (void)applicationWillTerminate:(UIApplication *)application
{
  [self saveContext];
}

- (void)saveContext
{
  NSError *error;
  if (_moc != nil) {
    if ([_moc hasChanges] && ![_moc save:&error]) {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

#pragma mark - Core Data stack

- (NSManagedObjectModel *)mom
{
  if (_mom != nil) {
    return _mom;
  }
  
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kNSMCoreDataModelFileName
                                            withExtension:@"momd"];
  _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  
  return _mom;
}

- (NSPersistentStoreCoordinator *)psc
{
  if (_psc != nil) {
    return _psc;
  }
  
  _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self mom]];
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *storeURL = [fm URLForDirectory:NSApplicationSupportDirectory
                                 inDomain:NSUserDomainMask
                        appropriateForURL:nil
                                   create:YES error:&err];
    if (storeURL == nil) {
      NSLog(@"access appsup dir: %@",[err localizedDescription]);
      abort();
    }
    storeURL = [storeURL URLByAppendingPathComponent:kNSMCoreDataStoreFileName];
    if (![fm fileExistsAtPath:[storeURL path]]) {
      NSURL *defaultStoreURL = [[NSBundle mainBundle]
                                URLForResource:kNSMCoreDataStoreFileName
                                withExtension:nil];
      if (defaultStoreURL != nil) {
        err = nil;
        [fm copyItemAtURL:defaultStoreURL toURL:storeURL error:&err];
        if (err != nil) {
          NSLog(@"copy to appsup dir: %@",[err localizedDescription]);
          abort();
        }
      }
    }
    
    NSPersistentStore *store = nil;
    err = nil;
    
    NSDictionary *opt_dict =
    @{NSMigratePersistentStoresAutomaticallyOption:@(YES),
      NSInferMappingModelAutomaticallyOption:@(YES)};
    
    store = [_psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:opt_dict
                                       error:&err];
    if (store == nil) {
      NSLog(@"add persistent store to coordinator:%@\n%@",[err localizedDescription], [err userInfo]);
      abort();
    }
  });
  return _psc;
}

- (NSManagedObjectContext *)moc
{
  if (_moc != nil) {
    return _moc;
  }
  
  if ([self psc] != nil) {
    _moc = [[NSManagedObjectContext alloc]
            initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_moc setPersistentStoreCoordinator:[self psc]];
  }
  return _moc;
}

@end
