//
//  GFDataSource.m
//  YuCloud
//
//  Created by guofengld on 16/3/24.
//  Copyright © 2016年 guofengld. All rights reserved.
//

#import "GFDataSource.h"

@interface GFDataSource () < NSFetchedResultsControllerDelegate >

@property (nonatomic, strong)   NSManagedObjectContext          *managedObjectContext;

@property (nonatomic, strong)   NSMutableDictionary             *operations;

@property (nonatomic, strong)   NSMutableDictionary             *dicFetchedResultsController;
@property (nonatomic, strong)   NSMapTable                      *dicDelegate;

@property (nonatomic, strong)   NSOperationQueue                *operationQueue;

@end

@implementation GFDataSource

+ (instancetype)sharedClient {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedContex {
    if (self = [super init]) {
        self.managedObjectContext = managedContex;
    }
    
    return self;
}

- (GFObjectOperation *)newProcessor {
    NSAssert(NO, @"implement this method in your sub class");
    return nil;
}

- (NSMutableDictionary *)operations {
    if (_operations == nil) {
        _operations = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _operations;
}

- (NSMutableDictionary *)dicFetchedResultsController {
    if (_dicFetchedResultsController == nil) {
        _dicFetchedResultsController = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _dicFetchedResultsController;
}

- (NSMapTable *)dicDelegate {
    if (!_dicDelegate) {
        _dicDelegate = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                             valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _dicDelegate;
}

- (void)registerDelegate:(id<GFDataSourceDelegate>)delegate
                  entity:(NSString *)entityName
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
      sectionNameKeyPath:(NSString *)sectionNameKeyPath
                     key:(NSString *)key {
    
    NSFetchedResultsController *controller = [self fetchedResultsControllerForKey:key
                                                                           entity:entityName
                                                                  sortDescriptors:sortDescriptors
                                                               sectionNameKeyPath:sectionNameKeyPath];
    if (predicate) {
        [controller.fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors) {
        [controller.fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    [self setDelegate:delegate forKey:key];
    [controller performFetch:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key
                                                        entity:(NSString *)entityName
                                               sortDescriptors:(NSArray *)sortDescriptors
                                            sectionNameKeyPath:(NSString *)sectionNameKeyPath {
    NSFetchedResultsController *controller = [self fetchedResultsControllerForKey:key];
    if (!controller) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Create and initialize the fetch results controller.
        controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                         managedObjectContext:self.managedObjectContext
                                                           sectionNameKeyPath:sectionNameKeyPath
                                                                    cacheName:nil];
        controller.delegate = self;
        
        [self setFetchedResultsController:controller forKey:key];
        [controller performFetch:nil];
    }
    
    return controller;
}

- (NSInteger)numberOfSectionsForKey:(NSString *)key {
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForKey:key];
    return [[fetchedResultsController sections] count];
}

- (NSInteger)numberOfItemsForKey:(NSString *)key inSection:(NSInteger)section {
    NSArray *sections = [[self fetchedResultsControllerForKey:key] sections];
    if ([sections count] == 0) {
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath forKey:(NSString *)key {
    NSInteger count = [self numberOfItemsForKey:key inSection:indexPath.section];
    if (indexPath.row >= count) {
        return nil;
    }
    
    return [[self fetchedResultsControllerForKey:key] objectAtIndexPath:indexPath];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section
                                                     key:(NSString *)key {
    NSArray *sections = [[self fetchedResultsControllerForKey:key] sections];
    if ([sections count] == 0) {
        return nil;
    }
    
    return [sections objectAtIndex:section];
}

- (NSArray *)allObjectsForKey:(NSString *)key {
    return [[self fetchedResultsControllerForKey:key] fetchedObjects];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forKey:(NSString *)key {
    [self.dicFetchedResultsController setObject:fetchedResultsController forKey:key];
}

- (void)setDelegate:(id <GFDataSourceDelegate>)delegate forKey:(NSString *)key {
    [self.dicDelegate setObject:delegate forKey:key];
}

- (NSFetchedResultsController *)fetchedResultsControllerForKey:(NSString *)key {
    return [self.dicFetchedResultsController objectForKey:key];
}

- (id <GFDataSourceDelegate>)delegateForKey:(NSString *)key {
    return [self.dicDelegate objectForKey:key];
}

- (NSString *)keyForController:(NSFetchedResultsController *)controller {
    for (NSString *key in [self.dicFetchedResultsController keyEnumerator]) {
        if ([self.self.dicFetchedResultsController objectForKey:key] == controller) {
            return key;
        }
    }
    
    return nil;
}

- (id <GFDataSourceDelegate>)delegateForController:(NSFetchedResultsController *)controller {
    NSString *key = [self keyForController:controller];
    return [self.dicDelegate objectForKey:key];
}

- (NSEnumerator <NSFetchedResultsController *> *)fetchedResultsControllerEnumerator {
    return [self.dicFetchedResultsController objectEnumerator];
}

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.name = [NSString stringWithFormat:@"%@ queue", NSStringFromClass([self class])];
    }
    
    return _operationQueue;
}

- (NSOperation *)addOperation:(GFObjectOperation *)processor wait:(BOOL)wait {
    processor.delegate = self;
    processor.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
    
    return [self addOperation:processor
                         wait:wait
                  finishBlock:nil];
}

- (NSOperation *)addOperation:(GFObjectOperation *)processor
                         wait:(BOOL)wait
                  finishBlock:(CommonBlock)block {
    processor.delegate = self;
    processor.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
    
    [self.operationQueue addOperations:@[processor] waitUntilFinished:wait];
    if (block) {
        [self.operations setObject:block forKey:processor.identifier];
    }
    
    return processor;
}

- (void)processDidFinished:(GFObjectOperation *)processor {
    if ([NSThread isMainThread]) {
        CommonBlock block = [self.operations objectForKey:processor.identifier];
        if (block) {
            block(YES, nil);
        }
        [self.operations removeObjectForKey:processor.identifier];
    }
    else {
        [self performSelectorOnMainThread:@selector(processDidFinished:)
                               withObject:processor
                            waitUntilDone:NO];
    }
}

- (void)startSync {
    NSAssert(NO, @"Need to implement %s in sub class", __PRETTY_FUNCTION__);
}

- (void)finishSync {
    NSAssert(NO, @"Need to implement %s in sub class", __PRETTY_FUNCTION__);
}

- (void)startSyncEntity:(NSString *)entity predicate:(NSPredicate *)predicate {
    GFObjectOperation *process = [self newProcessor];
    if (predicate) {
        [process.startSyncDataInfo addObject:@{@"entity" : entity, @"predicate" : predicate}];
    }
    else {
        [process.startSyncDataInfo addObject:@{@"entity" : entity}];
    }
    
    [self addOperation:process wait:YES];
}

- (void)finishSyncEntity:(NSString *)entity predicate:(NSPredicate *)predicate {
    GFObjectOperation *process = [self newProcessor];
    if (predicate) {
        [process.finishSyncDataInfo addObject:@{@"entity" : entity, @"predicate" : predicate}];
    }
    else {
        [process.finishSyncDataInfo addObject:@{@"entity" : entity}];
    }
    
    [self addOperation:process wait:YES];
}

- (NSOperation *)addObject:(id)data {
    GFObjectOperation *process = [self newProcessor];
    [process.insertDataInfo addObject:data];
    
    return [self addOperation:process wait:YES];
}

- (NSOperation *)addObject:(id)data block:(CommonBlock)block {
    GFObjectOperation *process = [self newProcessor];
    [process.insertDataInfo addObject:data];
    
    return [self addOperation:process wait:YES finishBlock:block];
}

- (void)addObjects:(NSArray *)array {
    GFObjectOperation *process = [self newProcessor];
    [process.insertDataInfo addObjectsFromArray:array];
    
    [self addOperation:process wait:YES];
}

- (void)editObject:(id)data {
    [self editObject:data block:nil];
}

- (void)editObject:(id)data block:(CommonBlock)block {
    GFObjectOperation *process = [self newProcessor];
    [process.editDataInfo addObject:data];
    
    [self addOperation:process wait:YES finishBlock:block];
}

- (void)clearData:(id)data {
    GFObjectOperation *process = [self newProcessor];
    [process.clearDataInfo addObject:data];
    
    [self addOperation:process wait:YES];
}

- (void)removeObjectWithObjectID:(NSManagedObjectID *)objectID {
    [self removeObjectWithObjectID:objectID block:nil];
}

- (void)removeObjectWithObjectID:(NSManagedObjectID *)objectID block:(CommonBlock)block {
    NSDictionary *info = @{@"objectID" : objectID,
                           @"action" : @"Delete"};
    
    [self editObject:info block:block];
}

#pragma mark - ObjectProcessDelegate

- (void)editDidSave:(NSNotification *)saveNotification {
    if ([NSThread isMainThread]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
    }
    else {
        [self performSelectorOnMainThread:@selector(editDidSave:)
                               withObject:saveNotification
                            waitUntilDone:NO];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataModal:willChangeContentForKey:)]) {
        [delegate dataModal:self willChangeContentForKey:key];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataModal:didChangeContentForKey:)]) {
        [delegate dataModal:self didChangeContentForKey:key];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataModal:didChangeSection:atIndex:forChangeType:forKey:)]) {
        [delegate dataModal:self
           didChangeSection:sectionInfo
                    atIndex:sectionIndex
              forChangeType:type
                     forKey:key];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSString *key = [self keyForController:controller];
    id <GFDataSourceDelegate> delegate = [self delegateForController:controller];
    
    if ([delegate respondsToSelector:@selector(dataModal:didChangeObject:atIndexPath:forChangeType:newIndexPath:forKey:)]) {
        [delegate dataModal:self didChangeObject:anObject
                atIndexPath:indexPath
              forChangeType:type
               newIndexPath:newIndexPath
                     forKey:key];
    }
}

@end