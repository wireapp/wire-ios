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


#import "VoiceChannelCollectionViewLayout.h"

@interface VoiceChannelCollectionViewLayout ()

@property (nonatomic) NSArray *insertedIndexPathsToAnimate;
@property (nonatomic) NSArray *deletedIndexPathsToAnimate;

@end

@implementation VoiceChannelCollectionViewLayout

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [super prepareForCollectionViewUpdates:updateItems];
    
    NSMutableArray *insertedIndexPaths = [NSMutableArray array];
    NSMutableArray *deletedIndexPaths = [NSMutableArray array];
    
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch (updateItem.updateAction) {
            case UICollectionUpdateActionInsert:
                [insertedIndexPaths addObject:updateItem.indexPathAfterUpdate];
                break;
            case UICollectionUpdateActionDelete:
                [deletedIndexPaths addObject:updateItem.indexPathBeforeUpdate];
                break;
            default:
                break;
        }
    }
    
    self.insertedIndexPathsToAnimate = insertedIndexPaths;
    self.deletedIndexPathsToAnimate = deletedIndexPaths;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:itemIndexPath];
    
    if ([self.insertedIndexPathsToAnimate containsObject:itemIndexPath]) {
        attributes.alpha = 1;
        attributes.center = CGPointMake(attributes.center.x, -attributes.size.height);
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if ([self.deletedIndexPathsToAnimate containsObject:itemIndexPath]) {
        attributes.alpha = 0;
        attributes.center = CGPointMake(attributes.center.x, -attributes.size.height);
    }
    
    return attributes;
}

@end
