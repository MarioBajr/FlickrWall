//
//  NSManagedObjectContext+Extensions.m
//  FlickerWall
//
//  Created by Mario Barbosa on 25/2/11.
//  Copyright 2011 Mario Barbosa. All rights reserved.
//

#import "NSManagedObjectContext+Extensions.h"

#define BATCH_SIZE 20

@implementation NSManagedObjectContext (NSManagedObjectContextExtensions)


#pragma mark - Context Manager

- (void)saveContext
{
	NSError *error = nil;
	
	if (![self save:&error]) 
	{
		LOG_ERR(error);
		[self rollbackContext];
	}
}

- (void)rollbackContext
{
	if ([self hasChanges]) 
	{
		[self rollback];
	}
}

#pragma mark - Core Objects Manager

- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate
{
	return [self fetchedResultsControllerFromClass:objectClass 
								withSortDescriptor:sortDescriptor 
									 withPredicate:predicate 
									   withSection:nil 
									 withCacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate 
													  withSection:(NSString *)section
													withCacheName:(NSString *)cacheName
{
	return [self fetchedResultsControllerFromClass:objectClass 
								withSortDescriptor:sortDescriptor 
									 withPredicate:predicate 
									   withSection:section 
									 withCacheName:cacheName 
										 withLimit:0];
}

- (NSFetchedResultsController *)fetchedResultsControllerFromClass:(Class)objectClass 
											   withSortDescriptor:(NSArray *)sortDescriptor
													withPredicate:(NSPredicate *)predicate 
													  withSection:(NSString *)section
													withCacheName:(NSString *)cacheName 
														withLimit:(NSInteger)limit
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
	NSEntityDescription *entity = [NSEntityDescription entityForName:[objectClass description] 
											  inManagedObjectContext:self];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:BATCH_SIZE];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:limit];
    
	[fetchRequest setSortDescriptors:sortDescriptor];
	
    NSFetchedResultsController *fetchedResultsController = 
	[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
										managedObjectContext:self 
										  sectionNameKeyPath:section 
												   cacheName:cacheName];
	
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error])
	{
		LOG_ERR(error);
	}
    
    return fetchedResultsController;
}

- (NSArray *)fetchAllObjectsOfClass:(Class)objectClass 
					  withPredicate:(NSPredicate *)predicate
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:[objectClass description] 
											  inManagedObjectContext:self];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	[request setReturnsObjectsAsFaults:NO];
	
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];
	if (error)
	{
		LOG_ERR(error);
	}
	
	return results;
}

- (NSInteger)countAllObjectsOfClass:(Class)objectClass
					  withPredicate:(NSPredicate *)predicate
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:[objectClass description]
											  inManagedObjectContext:self];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	NSInteger count = [self countForFetchRequest:request error:&error];
	if (error)
	{
		LOG_ERR(error);
	}
	
	return count;
}

- (NSManagedObject *)createObjectFromClass:(Class)objectClass
{
	NSManagedObject *object = 
	(NSManagedObject *)[NSEntityDescription insertNewObjectForEntityForName:[objectClass description] 
													 inManagedObjectContext:self];
	return object;
}

- (void)removeAllObjectsOfClass:(Class)objectClass 
				  withPredicate:(NSPredicate *)predicate
{
	NSArray *objects = [self fetchAllObjectsOfClass:objectClass withPredicate:predicate];
	for (NSManagedObject *object in objects)
		[self deleteObject:object];
	[self saveContext];
}

@end