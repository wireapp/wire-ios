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



typedef NS_ENUM(int8_t, ZMSetChangeMoveType) {
    ZMSetChangeMoveTypeNone, ///< No moves.
    
    /// With this move type, each performed move, affects indexes of all elements. The moved are only movingful if applied in the given order. A single move from index 3 to index 0 would (implicitply) cause elemnts originally at indexes 0, 1 and 2 to shift to indexes 1, 2 and 3 respectively.
    ZMSetChangeMoveTypeNSTableView,
    
    /// With this move type anything that is no longer at the index it was originally at, is considered moved. From indexes are the original indexes. To indexes are the final position. If index 3 is moved to index 0, there needs to be another move, that moves item at index 0 to another position.
    ZMSetChangeMoveTypeUICollectionView,
};
