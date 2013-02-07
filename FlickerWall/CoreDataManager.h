//
//  CoreDataManager.h
//  FlickerWall
//
//  Created by Mário Barbosa on 7/6/12.
//  Copyright (c) 2012 Mario Barbosa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObjectContext+Extensions.h"

typedef void (^CoreDataManagerResponseBlock)(void);

@interface CoreDataManager : NSObject

@property (strong, nonatomic, readonly) UIManagedDocument *document;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

+ (id)sharedCoreDataManager;

- (void)saveContext;
- (void)rollbackContext;
- (void)onCoreDataOpen:(CoreDataManagerResponseBlock) response;

@end