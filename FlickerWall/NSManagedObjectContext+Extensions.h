//
//  NSManagedObjectContext+Extensions.h
//  FlickerWall
//
//  Created by Mario Barbosa on 25/2/11.
//  Copyright 2011 Mario Barbosa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (NSManagedObjectContextExtensions)

#pragma mark - Context Manager

- (void)saveContext;
- (void)rollbackContext;

#pragma mark - Core Objects Manager

- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate;
- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate 
													  withSection:(NSString *)section
													withCacheName:(NSString *)cacheName;
- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate 
													  withSection:(NSString *)section
													withCacheName:(NSString *)cacheName 
														withLimit:(NSInteger)limit;
- (NSArray *)fetchAllObjectsOfClass:(Class)objectClass 
					  withPredicate:(NSPredicate *)predicate;
- (NSInteger)countAllObjectsOfClass:(Class)objectClass
					  withPredicate:(NSPredicate *)predicate;
- (NSManagedObject *)createObjectFromClass:(Class)objectClass;
- (void)removeAllObjectsOfClass:(Class)objectClass 
				  withPredicate:(NSPredicate *)predicate;

@end