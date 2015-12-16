//
//  LvMultiThreadCoreDataDao.h
//  GalaToy
//
//  Created by 彭光波 on 15-4-17.
//
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef void(^OperationResult)(NSError* error);

/**
 *  NSmanagedObject处理器
 */
typedef void (^NSManagedObjectOperator)(NSManagedObject *managedObj);
typedef void(^NSManagedObjectFilterListResult)(NSArray* result, NSError *error);
typedef void(^NSManagedObjectFilterCountResult)(NSInteger count, NSError *error);

/**
 *  列表结果处理，转化为另一个列表
 */
typedef NSArray* (^NSManagedObjectFilterListResultProcessor)(NSArray *results,
                                                             NSError *error);

/**
 *  A safety way to use Core Data under multi-thread
 */
@interface LvMultiThreadCoreDataDao : NSObject

@property (readonly ,strong, nonatomic) NSManagedObjectContext *bgObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainObjectContext;

- (void)setupEnvModel:(NSString *)model DbFile:(NSString*)filename;

- (NSManagedObjectContext *)createPrivateObjectContext;

- (void)createNewOfManagedObjectClassName:(NSString *)className operate:(NSManagedObjectOperator)operate;

- (void)delObjectWithFetchRequest:(NSFetchRequest *)fetchRequest;

- (NSArray *)filterObjectIDWithFetchRequest:(NSFetchRequest *)fetchRequest;

- (void)filterObjectIDWithFetchRequest:(NSFetchRequest *)fetchRequest
                               handler:(NSManagedObjectFilterListResult)handler;

/**
 *  过滤查询
 *  @param fetchRequest     查询实体
 *  @param processor        查询结果处理器，它返回的结果将作为该方法的返回结果
 */
- (NSArray *)filterObjectWithFetchRequest:(NSFetchRequest *)fetchRequest
                                processor:(NSManagedObjectFilterListResultProcessor)processor;

- (void)filterObjectWithFetchRequest:(NSFetchRequest *)fetchRequest
                             handler:(NSManagedObjectFilterListResult)handler;

- (NSInteger)countWithFetchRequest:(NSFetchRequest *)fetchRequest;

- (void)countWithFetchRequest:(NSFetchRequest *)fetchRequest
                      handler:(NSManagedObjectFilterCountResult)handler;



/**
 *  保存到文件
 */
- (void)saveToStorageFile;

/**
 *  删除存储文件
 */
- (void)removeStorageFile;

@end
