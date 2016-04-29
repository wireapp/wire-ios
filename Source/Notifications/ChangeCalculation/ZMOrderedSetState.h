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



/// This class wraps a C++ stdlib std::vector<intptr_t>
/// Wrapping it allows pure ObjC classes to pass this state around.
@interface ZMOrderedSetState : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOrderedSet:(NSOrderedSet *)orderedSet NS_DESIGNATED_INITIALIZER;

@end



@interface ZMOrderedSetState (ZMTrace)

- (intptr_t)traceSize;
- (intptr_t *)traceState;

@end
