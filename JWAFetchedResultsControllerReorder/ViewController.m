//
//  ViewController.m
//  JWAFetchedResultsControllerReorder
//
//  Created by Jake Walker on 7/25/16.
//  Copyright © 2016 Jake Walker. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Item.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate> {
    BOOL isReorderMode;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = delegate.managedObjectContext;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)insertNewObject:(id)sender {
    
    Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
    
    Item *lastItem = [self.fetchedResultsController.fetchedObjects lastObject];
    NSNumber *lastItemNumber;
    if (lastItem.displayOrder == NULL) {
        lastItemNumber = [NSNumber numberWithInteger:0];
    }
    else {
        lastItemNumber = [NSNumber numberWithInteger:lastItem.displayOrder.integerValue + 1];
    }
    newItem.displayOrder = lastItemNumber;
    NSString *randomAlphabet = [NSString stringWithFormat:@"%c", arc4random_uniform(26) + 'A'];
    newItem.itemName = [NSString stringWithFormat:@"Name %@", randomAlphabet ];
    
    // Save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        
        NSLog(@"Save Failed! %@ %@", error, [error localizedDescription]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSFetchedResultsController Delegate

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Fetch Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Item"];
    [fetchRequest setFetchBatchSize:20];
    
    // Sort Descriptor
    NSSortDescriptor *displayOrder = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    NSArray *sortDescriptors = @[displayOrder];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Fetched Results Controller
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    if (isReorderMode) return;
    
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (isReorderMode) return;
    
    UITableView *tableView = self.tableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    if (isReorderMode) return;
    
    [self.tableView endUpdates];
}

#pragma mark - UITableView Datasource and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ItemCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

// Configure Cell
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    cell.showsReorderControl = YES;
    
    Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@, Order %@", item.itemName, [item.displayOrder stringValue]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    if (sourceIndexPath.row == destinationIndexPath.row) return;
    
    isReorderMode = YES;
    
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSMutableArray *sortedItems = [NSMutableArray arrayWithArray:[self.fetchedResultsController fetchedObjects]];
    
    Item *movedItem = [sortedItems objectAtIndex:sourceIndexPath.row];
    
    [sortedItems removeObjectAtIndex:sourceIndexPath.row];
    
    [sortedItems insertObject:movedItem atIndex:destinationIndexPath.row];
    
    // Update displayOrder with indexes from the mutable array
    [sortedItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Item *itemObjects = (Item *)obj;
        itemObjects.displayOrder = [NSNumber numberWithInteger:idx];
    }];
    
    // Save
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Save Failed! %@ %@", error, [error localizedDescription]);
    }
    
    isReorderMode = NO;
}

- (void)updateDisplayOrder {
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    NSMutableArray *sortedItems = [NSMutableArray arrayWithArray:[self.fetchedResultsController fetchedObjects]];
    
    if (sortedItems.count == 0) return;
    
    // Update displayOrder with indexes from the mutable array
    [sortedItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Item *itemObjects = (Item *)obj;
        itemObjects.displayOrder = [NSNumber numberWithInteger:idx];
    }];
    
    // Save
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Save Failed! %@ %@", error, [error localizedDescription]);
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Item *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if (item) {
            [self.fetchedResultsController.managedObjectContext deleteObject:item];
            
            // Save
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                
                NSLog(@"Save Failed! %@ %@", error, [error localizedDescription]);
            }
            
            [self updateDisplayOrder];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    [self updateDisplayOrder];
}

@end
