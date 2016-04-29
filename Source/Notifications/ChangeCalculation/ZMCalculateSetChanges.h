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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import <Foundation/Foundation.h>

#import <vector>
#import "ZMSetChangeMoveType.h"



extern bool ZMCalculateSetChangesWithType(std::vector<intptr_t> const &startState, std::vector<intptr_t> const &endState, std::vector<intptr_t> const &updatedState,
        std::vector<size_t> &deletedIndexes, std::vector<intptr_t> &deletedObjects, std::vector<size_t> &insertedIndexes, std::vector<size_t> &updatedIndexes,
        std::vector<std::pair<size_t, size_t>> &movedIndexes, ZMSetChangeMoveType const moveType);
