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


#import "ZMOrderedSetState+Internal.h"

#if __has_feature(objc_arc)
#error This file must be compiled without ARC / -fno-objc-arc
#endif



@implementation ZMOrderedSetState

- (instancetype)initWithOrderedSet:(NSOrderedSet *)orderedSet;
{
    self = [super init];
    if (self) {
        _state.resize(orderedSet.count);
        [orderedSet getObjects:(id *) _state.data() range:NSMakeRange(0, orderedSet.count)];
    }
    return self;
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:ZMOrderedSetState.class]) {
        return NO;
    }
    ZMOrderedSetState *other = object;
    return self->_state == other->_state;
}

- (NSString *)description
{
    NSMutableArray *items = [NSMutableArray array];
    std::for_each(_state.cbegin(), _state.cend(), [items](intptr_t const &v){
        [items addObject:[NSString stringWithFormat:@"%p", (void *) v]];
    });
    return [NSString stringWithFormat:@"<%@: %p> count = %zu, {%@}",
            self.class, self,
            _state.size(), [items componentsJoinedByString:@", "]];
}

@end



@implementation ZMOrderedSetState (ZMTrace)

- (intptr_t)traceSize;
{
    return (intptr_t) self->_state.size();
}

- (intptr_t *)traceState;
{
    return self->_state.data();
}

@end
