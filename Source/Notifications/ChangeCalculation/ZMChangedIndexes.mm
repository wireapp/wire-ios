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


#import <WireSystem/WireSystem.h>
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState+Internal.h"
#import "ZMCalculateSetChanges.h"

@interface NSIndexSet (ZMChangedIndexes)

+ (instancetype)indexSetWithVector:(std::vector<size_t> const)indexes;

@end

@interface NSSet (ZMChangedIndexes)

+ (instancetype)setWithVector:(std::vector<intptr_t> const)objects;

@end



@interface ZMChangedIndexes ()
{
    std::vector<std::pair<size_t, size_t> > _movedIndexes;
}

@property (nonatomic) ZMOrderedSetState *startState;
@property (nonatomic) ZMOrderedSetState *endState;
@property (nonatomic) ZMOrderedSetState *updatedState;
@property (nonatomic) ZMSetChangeMoveType moveType;
@property (nonatomic) BOOL didCalculateChanges;

@property (nonatomic) BOOL requiresReload;
@property (nonatomic) NSIndexSet *deletedIndexes;
@property (nonatomic) NSIndexSet *insertedIndexes;
@property (nonatomic) NSIndexSet *updatedIndexes;
@property (nonatomic) NSSet *deletedObjects;

@end



@implementation ZMChangedIndexes

- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState;
{
    return [self initWithStartState:startState endState:endState updatedState:updatedState moveType:ZMSetChangeMoveTypeNSTableView];
}

- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState moveType:(ZMSetChangeMoveType)moveType;
{
    VerifyReturnNil(startState != nil);
    VerifyReturnNil(endState != nil);
    VerifyReturnNil(updatedState != nil);
    self = [super init];
    if (self != nil) {
        self.startState = startState;
        self.endState = endState;
        self.updatedState = updatedState;
        self.moveType = moveType;
    }
    return self;
}

- (void)calculateChangesIfNeeded;
{
    if (self.didCalculateChanges) {
        return;
    }
    [self calculateChanges];
    self.didCalculateChanges = YES;
    self.startState = nil;
    self.endState = nil;
    self.updatedState = nil;
}

- (void)calculateChanges;
{
    std::vector<size_t> deletedIndexes;
    std::vector<size_t> insertedIndexes;
    std::vector<size_t> updatedIndexes;
    std::vector<intptr_t> deletedObjects;
    
    if (! ZMCalculateSetChangesWithType(self.startState->_state, self.endState->_state, self.updatedState->_state, deletedIndexes, deletedObjects, insertedIndexes, updatedIndexes, _movedIndexes, self.moveType))
    {
        self.requiresReload = YES;
    } else {
        self.deletedIndexes = [NSIndexSet indexSetWithVector:deletedIndexes];
        self.deletedObjects = [NSSet setWithVector:deletedObjects];
        self.insertedIndexes = [NSIndexSet indexSetWithVector:insertedIndexes];
        self.updatedIndexes = [NSIndexSet indexSetWithVector:updatedIndexes];
    }
}

- (BOOL)requiresReload;
{
    [self calculateChangesIfNeeded];
    return _requiresReload;
}

- (NSIndexSet *)deletedIndexes;
{
    [self calculateChangesIfNeeded];
    return _deletedIndexes;
}

- (NSIndexSet *)insertedIndexes;
{
    [self calculateChangesIfNeeded];
    return _insertedIndexes;
}

- (NSIndexSet *)updatedIndexes;
{
    [self calculateChangesIfNeeded];
    return _updatedIndexes;
}

- (void)enumerateMovedIndexes:(void(^)(NSUInteger from, NSUInteger to))block;
{
    [self calculateChangesIfNeeded];
    for(auto pair : _movedIndexes) {
        block(pair.first, pair.second);
    }
}

@end



@implementation NSIndexSet (ZMChangedIndexes)

+ (instancetype)indexSetWithVector:(std::vector<size_t> const)indexes;
{
    NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
    std::for_each(indexes.cbegin(), indexes.cend(), [&set](size_t idx){
        [set addIndex:idx];
    });
    return [set copy];
}

@end

@implementation NSSet (ZMChangedIndexes)

+ (instancetype)setWithVector:(std::vector<intptr_t> const)objects;
{
    CFMutableSetRef set = (__bridge CFMutableSetRef)[NSMutableSet set];
    std::for_each(objects.cbegin(), objects.cend(), [&set](intptr_t obj){
        CFSetAddValue(set, (void *)obj);
    });
    return [(__bridge NSMutableSet*)set copy];
}

@end
