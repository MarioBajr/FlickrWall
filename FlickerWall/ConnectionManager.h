//
//  ConnectionManager.h
//  FlickerWall
//
//  Created by Mario Barbosa on 2/5/13.
//  Copyright (c) 2013 Mario. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FetchCompletionHandler)(BOOL success);

@interface ConnectionManager : NSObject

+ (void)fetchWithCompletionHandler:(FetchCompletionHandler)completionHandler;

@end
