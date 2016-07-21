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

/**
 * Abstract.
 * This class is designed to provide index path access to several arrays of objects as a single array of objects with
 * continuous index.
 * 
 * Idea.
 * Let's imagine we have a several arrays, and we want to represent it as a single one:
 * We have: A_1[0...k_1] ... A_n[0...k_n]
 * We would like to see it as
 * A_sum[0... \sum_{i=1}^n k_i]
 * with direct by-index access.
 *
 * Practical applications.
 * In table view several logical data sources could be displayed at once one by one, like self conversation, incomming
 * connection requests followed by the conversations list.
 */

@interface AggregateArray : NSObject

- (instancetype)initWithSections:(NSArray *)sections;
+ (instancetype)aggregateArrayWithSections:(NSArray *)array;

- (NSUInteger)itemCount;

/**
 * @return total number of sections in this array
 */
- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex;
- (id<NSObject>)itemForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItem:(id<NSObject>)object;

- (NSArray *)sectionAtIndex:(NSUInteger)sectionIndex;

- (NSIndexPath *)convertLocalIndexPath:(NSIndexPath *)local fromSection:(NSUInteger)sectionIndex;

#pragma mark - Enumeration
- (void)enumerateItems:(void(^)(NSArray *section, NSUInteger sectionIndex, id<NSObject> item, NSUInteger itemIndex, BOOL *stop))enumerator;
- (void)enumerateSections:(void(^)(NSArray *section, NSUInteger sectionIndex, BOOL *stop))enumerator;

@end
