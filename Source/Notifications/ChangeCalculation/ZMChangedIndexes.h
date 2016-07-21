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


#import <Foundation/Foundation.h>
#import "ZMSetChangeMoveType.h"
@class ZMOrderedSetState;



@interface ZMChangedIndexes : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState;
- (instancetype)initWithStartState:(ZMOrderedSetState *)startState endState:(ZMOrderedSetState *)endState updatedState:(ZMOrderedSetState *)updatedState moveType:(ZMSetChangeMoveType)moveType NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL requiresReload;
@property (nonatomic, readonly) NSIndexSet *deletedIndexes;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *updatedIndexes;
@property (nonatomic, readonly) NSSet *deletedObjects;

- (void)enumerateMovedIndexes:(void(^)(NSUInteger from, NSUInteger to))block;

@end
