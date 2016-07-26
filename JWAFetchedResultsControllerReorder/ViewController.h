//
//  ViewController.h
//  JWAFetchedResultsControllerReorder
//
//  Created by Jake Walker on 7/25/16.
//  Copyright © 2016 Jake Walker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

