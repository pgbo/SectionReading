//
//  LvMultiThreadCoreDataDao.m
//  GalaToy
//
//  Created by 彭光波 on 15-4-17.
//
//

#import "LvMultiThreadCoreDataDao.h"

@interface LvMultiThreadCoreDataDao ()

@property (nonatomic, copy)NSString *modelName;
@property (nonatomic, copy)NSString *dbFileName;
@end

@implementation LvMultiThreadCoreDataDao

-(void) setupEnvModel:(NSString *)model DbFile:(NSString*)filename{
    _modelName = model;
    _dbFileName = filename;
    [self initCoreDataStack];
}

- (void)initCoreDataStack
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _bgObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_bgObjectContext setPersistentStoreCoordinator:coordinator];
        
        _mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainObjectContext setParentContext:_bgObjectContext];
    }
    
}


- (NSManagedObjectContext *)createPrivateObjectContext
{
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [ctx setParentContext:_mainObjectContext];
    
    return ctx;
}


- (NSManagedObjectModel *)managedObjectModel
{
    NSManagedObjectModel *managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_dbFileName];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                               NSInferMappingModelAutomaticallyOption : @YES };
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:options
                                                          error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (void)createNewOfManagedObjectClassName:(NSString *)className operate:(NSManagedObjectOperator)operator
{
    if (!className)
        return;
    
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    __block NSManagedObject *managedObj = nil;
    
    __weak typeof(self)weakSelf = self;
    [ctx performBlockAndWait:^{
        managedObj = [NSEntityDescription insertNewObjectForEntityForName:className
                                                   inManagedObjectContext:ctx];
        if (operator) {
            operator(managedObj);
        }
        
        // 保存
        [weakSelf saveContext:ctx handler:nil];
    }];
}

- (void)delObjectWithFetchRequest:(NSFetchRequest *)fetchRequest
{
    if (!fetchRequest)
        return;
    [self filterObjectWithFetchRequest:fetchRequest handler:^(NSArray *results, NSError *err){
        for (NSManagedObject *managedObj in results) {
            [self delManagedObject:managedObj];
        }
    }];
}

- (void)delManagedObject:(NSManagedObject *)managedObj
{
    if (!managedObj || !managedObj.managedObjectContext)
        return;
    
    __weak typeof(self)weakSelf = self;
    NSManagedObjectContext *ctx = managedObj.managedObjectContext;
    [ctx performBlockAndWait:^{
        if ([ctx objectRegisteredForID:managedObj.objectID]) {
            [ctx deleteObject:managedObj];
            [weakSelf saveContext:ctx handler:nil];
        }
    }];
}

- (NSArray *)filterObjectIDWithFetchRequest:(NSFetchRequest *)fetchRequest
{
    if (!fetchRequest)
        return nil;
    
    fetchRequest.resultType = NSManagedObjectIDResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __block NSArray *results = nil;
    [ctx performBlockAndWait:^{
        NSError *err;
        results = [ctx executeFetchRequest:fetchRequest error:&err];
    }];
    return results;
}

- (void)filterObjectIDWithFetchRequest:(NSFetchRequest *)fetchRequest
                               handler:(NSManagedObjectFilterListResult)handler
{
    if (!fetchRequest) {
        if (handler) {
            handler(nil, nil);
        }
        return;
    }
    
    fetchRequest.resultType = NSManagedObjectIDResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __weak typeof(self)weakSelf = self;
    [ctx performBlock:^{
        NSError *err;
        NSArray *results = [ctx executeFetchRequest:fetchRequest error:&err];
        if (handler) {
            handler(results, err);
        }
        
        // Final setp
        [weakSelf saveContext:ctx handler:nil];
    }];
}

- (NSArray *)filterObjectWithFetchRequest:(NSFetchRequest *)fetchRequest
                                processor:(NSManagedObjectFilterListResultProcessor)processor
{
    if (!fetchRequest)
        return nil;
    
    fetchRequest.resultType = NSManagedObjectResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __block NSArray *results = nil;
    [ctx performBlockAndWait:^{
        NSError *err;
        results = [ctx executeFetchRequest:fetchRequest error:&err];
        if (processor) {
            results = processor(results, err);
        }
    }];
    return results;
}


- (void)filterObjectWithFetchRequest:(NSFetchRequest *)fetchRequest
                             handler:(NSManagedObjectFilterListResult)handler
{
    if (!fetchRequest) {
        if (handler) {
            handler(nil, nil);
        }
        return;
    }
    
    fetchRequest.resultType = NSManagedObjectResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __weak typeof(self)weakSelf = self;
    [ctx performBlock:^{
        NSError *err;
        NSArray *results = [ctx executeFetchRequest:fetchRequest error:&err];
        if (handler) {
            handler(results, err);
        }
        
        // Final setp
        [weakSelf saveContext:ctx handler:nil];
    }];
}

- (NSInteger)countWithFetchRequest:(NSFetchRequest *)fetchRequest
{
    if (!fetchRequest)
        return 0;
    
    fetchRequest.resultType = NSCountResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __block NSInteger count = 0;
    [ctx performBlockAndWait:^{
        NSError *err;
        count = [ctx countForFetchRequest:fetchRequest error:&err];
    }];
    return count;
}

- (void)countWithFetchRequest:(NSFetchRequest *)fetchRequest
                      handler:(NSManagedObjectFilterCountResult)handler
{
    if (!fetchRequest) {
        if (handler) {
            handler(0, nil);
        }
        return;
    }
    
    fetchRequest.resultType = NSCountResultType;
    NSManagedObjectContext *ctx = [NSThread isMainThread]?self.mainObjectContext:[self createPrivateObjectContext];
    
    __weak typeof(self)weakSelf = self;
    [ctx performBlock:^{
        NSError *err;
        NSInteger count = [ctx countForFetchRequest:fetchRequest error:&err];
        if (handler) {
            handler(count, err);
        }
        
        // Final setp
        [weakSelf saveContext:ctx handler:nil];
    }];
}

- (void)saveToStorageFile
{
    [self saveContext:self.mainObjectContext handler:nil];
}

- (void)saveContext:(NSManagedObjectContext *)ctx handler:(OperationResult)handler
{
    if (!ctx || !ctx.hasChanges) {
        if (handler) {
            handler(nil);
        }
        return;
    }
    
    [ctx performBlockAndWait:^{
        NSError *error;
        [ctx save:&error];
        
        __block NSManagedObjectContext *parentCtx = ctx.parentContext;
        while (parentCtx && parentCtx.hasChanges) {
            [parentCtx performBlockAndWait:^{
                NSError *innerErr;
                [parentCtx save:&innerErr];
                parentCtx = parentCtx.parentContext;
            }];
        }
        
        if (handler) {
            handler(error);
        }
    }];
}



// 删除存储
- (void)removeStorageFile
{
    if (!_bgObjectContext)
        return;
    
    // 删除数据
    // Erase the persistent store from coordinator and also file manager.
    
    NSPersistentStoreCoordinator *persistentCoor =  _bgObjectContext.persistentStoreCoordinator;
    if (!persistentCoor)
        return;
    
    NSArray *persistentStores = persistentCoor.persistentStores;
    
    NSError *error = nil;
    NSURL *storeURL = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSPersistentStore *store in persistentStores) {
        storeURL = store.URL;
        [persistentCoor removePersistentStore:store error:&error];
        [fileManager removeItemAtURL:storeURL error:&error];
    }
}

@end
