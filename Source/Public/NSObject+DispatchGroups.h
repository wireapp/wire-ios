//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@import WireSystem;

@interface NSObject (DispatchGroups)

- (void)createDispatchGroups;

/// List of all groups associated with this context
- (NSArray<ZMSDispatchGroup *> *_Nonnull)allGroups;
- (ZMSDispatchGroup * _Nullable)firstGroup;

/// This is used for testing. It is not thread safe.
- (void)addGroup:(ZMSDispatchGroup * _Nonnull)dispatchGroup;

- (NSArray<ZMSDispatchGroup *> * _Nonnull)enterAllGroups;
- (void)leaveAllGroups:(NSArray<ZMSDispatchGroup *> * _Nonnull)groups;
- (NSArray<ZMSDispatchGroup *> * _Nonnull)enterAllButFirstGroup;

@end
