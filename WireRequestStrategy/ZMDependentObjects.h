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

@class ZMManagedObject;



@interface ZMDependentObjects : NSObject

- (void)addManagedObject:(ZMManagedObject *)managedObject withDependency:(id)dependency;

/// When the @c block returns @c YES the object will get removed from the reciver, otherwise it will stay registered with the given dependency.
- (void)enumerateManagedObjectsForDependency:(id )dependency withBlock:(BOOL(^)(ZMManagedObject *managedObject))block;

- (id)anyDependencyForObject:(ZMManagedObject *)dependant;

@end
