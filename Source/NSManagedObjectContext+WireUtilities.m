// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


@import WireSystem;
#import "NSManagedObjectContext+WireUtilities.h"
#import <objc/runtime.h>

static char const AssociatedGroupsKey;
static char const AssociatedIsolationKey;
static char const AssociatedPendingSaveCountKey;
static NSTimeInterval const PerformWarningTimeout = 10;

@implementation NSManagedObjectContext (ZMSGroupQueue)


- (void)createDispatchGroups;
{
    dispatch_queue_t isolation = dispatch_queue_create("context.isolation", DISPATCH_QUEUE_CONCURRENT);
    objc_setAssociatedObject(self, &AssociatedIsolationKey, isolation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_barrier_async(isolation, ^{
        NSMutableArray *groups = [NSMutableArray arrayWithObjects:
                                  [ZMSDispatchGroup groupWithLabel:@"ZMSGroupQueue first"],
                                    // The secondary group gets -performGroupedBlock: added to it, but is not affected by
                                    // -notifyWhenGroupIsEmpty: -- that method needs to add extra blocks to the firstGroup, though.
                                  [ZMSDispatchGroup groupWithLabel:@"ZMSGroupQueue second"],
                                  nil];
        objc_setAssociatedObject(self, &AssociatedGroupsKey, groups, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

- (NSArray *)allGroups;
{
    __block NSArray *result;
    dispatch_queue_t isolation = objc_getAssociatedObject(self, &AssociatedIsolationKey);
    RequireString(isolation != nil, "No isolation queue? Make sure to call -createDispatchGroups.");
    dispatch_sync(isolation, ^{
        result = [objc_getAssociatedObject(self,  &AssociatedGroupsKey) copy];
    });
    return result;
}

- (ZMSDispatchGroup *)firstGroup;
{
    __block ZMSDispatchGroup *result;
    dispatch_queue_t isolation = objc_getAssociatedObject(self, &AssociatedIsolationKey);
    RequireString(isolation != nil, "No isolation queue? Make sure to call -createDispatchGroups.");
    dispatch_sync(isolation, ^{
        result = [objc_getAssociatedObject(self,  &AssociatedGroupsKey) firstObject];
    });
    return result;
}

- (NSArray *)enterAllGroups;
{
    NSArray *groups = self.allGroups;
    for (ZMSDispatchGroup *g in groups) {
        [g enter];
    }
    return groups;
}

- (void)leaveAllGroups:(NSArray *)groups;
{
    for (ZMSDispatchGroup *g in groups) {
        [g leave];
    }
}

- (NSArray *)enterAllButFirstGroup;
{
    NSArray *groups = self.allGroups;
    groups = [groups subarrayWithRange:NSMakeRange(1, groups.count - 1)];
    for (ZMSDispatchGroup *g in groups) {
        [g enter];
    }
    return groups;
}

- (int)pendingSaveCounter;
{
    NSNumber *n = objc_getAssociatedObject(self,  &AssociatedPendingSaveCountKey);
    return [n intValue];
}
- (void)setPendingSaveCounter:(int)newCounter;
{
    objc_setAssociatedObject(self, &AssociatedPendingSaveCountKey, @(newCounter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)performGroupedBlock:(dispatch_block_t)block;
{
    NSArray *groups = [self enterAllGroups];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlock:^{
        [tp resetTime];
        block();
        [self leaveAllGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)performGroupedBlockAndWait:(dispatch_block_t)block;
{
    NSArray *groups = [self enterAllGroups];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlockAndWait:^{
        [tp resetTime];
        block();
        [self leaveAllGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)notifyWhenGroupIsEmpty:(dispatch_block_t)block;
{
    // We need to enter & leave all but the first group to make sure that any work added by
    // this method is stil being tracked by the other groups.
    NSArray *groups = [self enterAllButFirstGroup];
    ZMSDispatchGroup *g = self.dispatchGroup;
    VerifyReturn(g != nil);
    [g notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:block];
        [self leaveAllGroups:groups];
    }];
}

- (ZMSDispatchGroup *)dispatchGroup;
{
    return [self firstGroup];
}

- (void)addGroup:(ZMSDispatchGroup *)dispatchGroup;
{
    dispatch_queue_t isolation = objc_getAssociatedObject(self, &AssociatedIsolationKey);
    RequireString(isolation != nil, "No isolation queue? Make sure to call -createDispatchGroups.");
    dispatch_barrier_async(isolation, ^{
        NSMutableArray *groups = objc_getAssociatedObject(self,  &AssociatedGroupsKey);
        [groups addObject:dispatchGroup];
    });
}

- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;
{
    NSError *error;
    NSArray *result = [self executeFetchRequest:request error:&error];
    RequireString(result != nil, "Error in fetching: %lu", (long) error.code);
    return result;
}

@end
