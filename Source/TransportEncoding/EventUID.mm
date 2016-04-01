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


#include "EventUID.h"

const EventUID EventUID::UID_NONE(-1, 0);

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
EventUID::EventUID(int seq, uint64_t rnd) : sequence(seq), random(rnd) {
    
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator==(const EventUID& other) const {
    return sequence == other.sequence && random == other.random;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator!=(const EventUID& other) const {
    return !operator==(other);
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator<(const EventUID& other) const {
    return sequence < other.sequence || (sequence == other.sequence && random < other.random);
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator>(const EventUID& other) const {
    return sequence > other.sequence || (sequence == other.sequence && random > other.random);
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator<=(const EventUID& other) const {
    return operator==(other) || operator<(other);
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::operator>=(const EventUID& other) const {
    return operator==(other) || operator>(other);
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
bool EventUID::empty() const {
    return sequence < 0;
}
//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventUID::isNull()const {
    return empty();
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventUID::isSet()const {
    return !empty();
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
int EventUID::compare(const EventUID& other) const {
    if(operator==(other)) {
        return 0;
    }
    
    if(operator>(other)) {
        return 1;
    }
    else {
        return -1;
    }
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
NSString *EventUID::description() const {
    return [NSString stringWithFormat:@"%llx.%llx", (unsigned long long) sequence, (unsigned long long) random];
}
