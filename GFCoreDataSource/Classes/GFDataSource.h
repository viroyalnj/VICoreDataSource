//
//  GFDataSource.h
//  YuCloud
//
//  Created by guofengld on 16/3/24.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GFObjectOperation.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CommonBlock)(BOOL success, NSDictionary * _Nullable info);

@class GFDataSource;

@protocol GFDataSourceDelegate <NSObject>

@optional

- (void)dataModal:(GFDataSource *)modal willChangeContentForKey:(nullable NSString *)key;
- (void)dataModal:(GFDataSource *)modal didChangeContentForKey:(nullable NSString *)key;

- (void)dataModal:(GFDataSource *)modal
 didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type
           forKey:(nullable NSString *)key;

- (void)dataModal:(GFDataSource *)modal
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
           forKey:(nullable NSString *)key;

@optional

- (void)modelDataUpdated:(BOOL)inserted;

@end

@interface GFDataSource : NSObject < ObjectProcessDelegate >

@property (nonatomic, weak)     id <GFDataSourceDelegate>      delegate;
@property (nonatomic, readonly) NSManagedObjectContext          *managedObjectContext;

+ (instancetype)sharedClient;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex;

- (GFObjectOperation *)newProcessor;

- (void)registerDelegate:(id<GFDataSourceDelegate>)delegate
                  entity:(nonnull NSString *)entityName
               predicate:(nullable NSPredicate *)predicate
         sortDescriptors:(nonnull NSArray<NSSortDescriptor *>*)sortDescriptors
      sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath
                     key:(NSString *)key;

- (NSInteger)numberOfSectionsForKey:(NSString *)key;
- (NSInteger)numberOfItemsForKey:(NSString *)key inSection:(NSInteger)section;
- (nullable id)objectAtIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)key;
- (nullable id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section key:(NSString *)key;
- (NSArray *)allObjectsForKey:(NSString *)key;

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forKey:(NSString *)key;
- (void)setDelegate:(id <GFDataSourceDelegate>)delegate forKey:(NSString *)key;

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key;
- (id <GFDataSourceDelegate>)delegateForKey:(NSString *)key;
- (nullable NSString *)keyForController:(NSFetchedResultsController *)controller;
- (id <GFDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller;
- (NSEnumerator <NSFetchedResultsController *> *)fetchedResultsControllerEnumerator;

- (void)startSync;
- (void)finishSync;

- (void)startSyncEntity:(NSString *)entity predicate:(nullable NSPredicate *)predicate;
- (void)finishSyncEntity:(NSString *)entity predicate:(nullable NSPredicate *)predicate;

- (NSOperation *)addObject:(id)data;
- (NSOperation *)addObject:(id)data block:(nullable CommonBlock)block;
- (void)addObjects:(NSArray *)array;
- (void)editObject:(id)data;
- (void)editMessageObject:(id)data;
- (void)clearData:(id)data;
- (void)clearUnread:(id)data;

- (void)removeObjectWithObjectID:(NSManagedObjectID *)objectID;
- (void)removeObjectWithObjectID:(NSManagedObjectID *)objectID block:(nullable CommonBlock)block;

@end

NS_ASSUME_NONNULL_END