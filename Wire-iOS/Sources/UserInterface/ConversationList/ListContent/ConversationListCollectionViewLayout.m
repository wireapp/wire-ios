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


#import "ConversationListCollectionViewLayout.h"
#import "WAZUIMagicIOS.h"

@implementation ConversationListCollectionViewLayout

- (void)prepareLayout
{
    [super prepareLayout];
    
    CGFloat height = [[WAZUIMagic sharedMagic][@"list.tile_height"] floatValue];
    self.itemSize = CGSizeMake(self.collectionView.bounds.size.width, height);
    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = [[WAZUIMagic sharedMagic][@"list.tile_vertical_gap"] floatValue];
    self.sectionInset = UIEdgeInsetsZero;
}


@end
