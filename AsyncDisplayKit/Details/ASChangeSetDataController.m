//
//  ASChangeSetDataController.m
//  AsyncDisplayKit
//
//  Created by Huy Nguyen on 19/10/15.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//

#import "ASChangeSetDataController.h"
#import "ASInternalHelpers.h"
#import "_ASHierarchyChangeSet.h"
#import "ASAssert.h"
#import "NSIndexSet+ASHelpers.h"

#import "ASDataController+Subclasses.h"

@interface ASChangeSetDataController ()

@property (nonatomic, assign) NSUInteger changeSetBatchUpdateCounter;
@property (nonatomic, strong) _ASHierarchyChangeSet *changeSet;

@end

@implementation ASChangeSetDataController

#pragma mark - Batching (External API)

- (void)beginUpdates
{
  ASDisplayNodeAssertMainThread();
  if (_changeSetBatchUpdateCounter == 0) {
    _changeSet = [_ASHierarchyChangeSet new];
  }
  _changeSetBatchUpdateCounter++;
}

- (void)endUpdatesAnimated:(BOOL)animated completion:(void (^)(BOOL))completion
{
  ASDisplayNodeAssertMainThread();
  _changeSetBatchUpdateCounter--;
  
  if (_changeSetBatchUpdateCounter == 0) {
    [_changeSet markCompleted];
    
    [super beginUpdates];

    for (_ASHierarchyItemChange *change in [_changeSet itemChangesOfType:_ASHierarchyChangeTypeReload]) {
      [super deleteRowsAtIndexPaths:change.indexPaths withAnimationOptions:change.animationOptions];
    }
    
    for (_ASHierarchyItemChange *change in [_changeSet itemChangesOfType:_ASHierarchyChangeTypeDelete]) {
      [super deleteRowsAtIndexPaths:change.indexPaths withAnimationOptions:change.animationOptions];
    }
    
    for (_ASHierarchySectionChange *change in [_changeSet sectionChangesOfType:_ASHierarchyChangeTypeReload]) {
      [super deleteSections:change.indexSet withAnimationOptions:change.animationOptions];
    }
    
    for (_ASHierarchySectionChange *change in [_changeSet sectionChangesOfType:_ASHierarchyChangeTypeDelete]) {
      [super deleteSections:change.indexSet withAnimationOptions:change.animationOptions];
    }

    // TODO: Shouldn't reloads be processed before deletes, since deletes affect
    // the index space and reloads don't?
    for (_ASHierarchySectionChange *change in [_changeSet sectionChangesOfType:_ASHierarchyChangeTypeReload]) {
      NSIndexSet *newIndexes = [change.indexSet as_indexesByMapping:^(NSUInteger idx) {
        return [_changeSet newSectionForOldSection:idx];
      }];
      [super insertSections:newIndexes withAnimationOptions:change.animationOptions];
    }
    
    for (_ASHierarchySectionChange *change in [_changeSet sectionChangesOfType:_ASHierarchyChangeTypeInsert]) {
      [super insertSections:change.indexSet withAnimationOptions:change.animationOptions];
    }
    
    for (_ASHierarchyItemChange *change in [_changeSet itemChangesOfType:_ASHierarchyChangeTypeInsert]) {
      [super insertRowsAtIndexPaths:change.indexPaths withAnimationOptions:change.animationOptions];
    }

    [super endUpdatesAnimated:animated completion:completion];
    
    _changeSet = nil;
  }
}

- (BOOL)batchUpdating
{
  BOOL batchUpdating = (_changeSetBatchUpdateCounter != 0);
  // _changeSet must be available during batch update
  ASDisplayNodeAssertTrue(batchUpdating == (_changeSet != nil));
  return batchUpdating;
}

#pragma mark - Section Editing (External API)

- (void)insertSections:(NSIndexSet *)sections withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet insertSections:sections animationOptions:animationOptions];
  } else {
    [super insertSections:sections withAnimationOptions:animationOptions];
  }
}

- (void)deleteSections:(NSIndexSet *)sections withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet deleteSections:sections animationOptions:animationOptions];
  } else {
    [super deleteSections:sections withAnimationOptions:animationOptions];
  }
}

- (void)reloadSections:(NSIndexSet *)sections withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet reloadSections:sections animationOptions:animationOptions];
  } else {
    [super reloadSections:sections withAnimationOptions:animationOptions];
  }
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet deleteSections:[NSIndexSet indexSetWithIndex:section] animationOptions:animationOptions];
    [_changeSet insertSections:[NSIndexSet indexSetWithIndex:newSection] animationOptions:animationOptions];
  } else {
    [super moveSection:section toSection:newSection withAnimationOptions:animationOptions];
  }
}

#pragma mark - Row Editing (External API)

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet insertItems:indexPaths animationOptions:animationOptions];
  } else {
    [super insertRowsAtIndexPaths:indexPaths withAnimationOptions:animationOptions];
  }
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet deleteItems:indexPaths animationOptions:animationOptions];
  } else {
    [super deleteRowsAtIndexPaths:indexPaths withAnimationOptions:animationOptions];
  }
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet reloadItems:indexPaths animationOptions:animationOptions];
  } else {
    [super reloadRowsAtIndexPaths:indexPaths withAnimationOptions:animationOptions];
  }
}

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath withAnimationOptions:(ASDataControllerAnimationOptions)animationOptions
{
  ASDisplayNodeAssertMainThread();
  if ([self batchUpdating]) {
    [_changeSet deleteItems:@[indexPath] animationOptions:animationOptions];
    [_changeSet insertItems:@[newIndexPath] animationOptions:animationOptions];
  } else {
    [super moveRowAtIndexPath:indexPath toIndexPath:newIndexPath withAnimationOptions:animationOptions];
  }
}

@end