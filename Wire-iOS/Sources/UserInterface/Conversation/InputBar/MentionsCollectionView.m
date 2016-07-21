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


#import "MentionsCollectionView.h"



@implementation MentionsCollectionView

- (void)reloadData
{
    [super reloadData];
    [self invalidateIntrinsicContentSize];
}


- (CGSize)intrinsicContentSize
{
    
    NSInteger numberOfItems = [self.dataSource collectionView:self numberOfItemsInSection:0];
    NSInteger truncatedNumberOfItems = MIN(numberOfItems, 3);
    
    CGSize size = CGSizeZero;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.collectionViewLayout;

    size = CGSizeMake((32) * truncatedNumberOfItems + (truncatedNumberOfItems-1)*flowLayout.minimumInteritemSpacing, UIViewNoIntrinsicMetric);

    return size;
}

@end
