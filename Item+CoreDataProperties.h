//
//  Item+CoreDataProperties.h
//  JWAFetchedResultsControllerReorder
//
//  Created by Jake Walker on 7/25/16.
//  Copyright © 2016 Jake Walker. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Item.h"

NS_ASSUME_NONNULL_BEGIN

@interface Item (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *displayOrder;
@property (nullable, nonatomic, retain) NSString *itemName;

@end

NS_ASSUME_NONNULL_END
