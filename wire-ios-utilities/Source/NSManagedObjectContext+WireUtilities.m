//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
#import "WireUtilities/WireUtilities-Swift.h"
#import "NSManagedObjectContext+WireUtilities.h"
#import <objc/runtime.h>

@implementation NSManagedObjectContext (ZMSGroupQueue)

- (void)notifyWhenGroupIsEmpty:(dispatch_block_t)block;
{
    // We need to enter & leave all but the first group to make sure that any work added by
    // this method is stil being tracked by the other groups.
    ZMSDispatchGroup *firstGroup = self.dispatchGroup;
    NSArray *groups = [self.dispatchGroupContext enterAllExcept:firstGroup];
    VerifyReturn(firstGroup != nil);
    [firstGroup notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:block];
        [self.dispatchGroupContext leaveGroups:groups];
    }];
}

- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;
{
    NSError *error;
    NSArray *result = [self executeFetchRequest:request error:&error];
    RequireString(result != nil, "Error in fetching: %lu", (long) error.code);
    return result;
}

- (void)addGroup:(ZMSDispatchGroup *)dispatchGroup
{
    [self.dispatchGroupContext addGroup:dispatchGroup];
}

- (NSArray<ZMSDispatchGroup*> *)allGroups
{
    return self.dispatchGroupContext.groups;
}

- (NSArray<ZMSDispatchGroup*> *)enterAllGroups
{
    return [self.dispatchGroupContext enterAllExcept:nil];
}

- (void)leaveAllGroups:(NSArray<ZMSDispatchGroup*> *)groups
{
    [self.dispatchGroupContext leaveGroups:groups];
}

@end
