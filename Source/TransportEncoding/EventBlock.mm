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



#include "EventBlock.h"

namespace {
    const size_t EVENT_UID_SIZE = sizeof(EventUID::sequence) + sizeof(EventUID::random);
    const size_t BLOCK_SIZE = EVENT_UID_SIZE*2;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock::EventBlock(const EventBlock& other) : lowest(other.lowest), highest(other.highest) {
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock::EventBlock(const std::vector<EventUID>& list) {
    
    if(!list.empty()) {
        std::vector<EventUID> ordered(list.begin(), list.end());
        std::sort(ordered.begin(), ordered.end());
    
        lowest = *ordered.begin();
        highest = *(ordered.end() -1);
    }
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlock::addEvent(const EventUID& uid, bool authoritative) {
    
    if(!authoritative) {
        if(! canContain(uid)) {
            NSCAssert(false, @"Can't contain");
            return;
        }
    }
    
	if(empty()) {
        lowest = highest = uid;
    }
    else {
        if(highest < uid) {
            NSCAssert(authoritative || highest.sequence == uid.sequence || highest.sequence +1 == uid.sequence, @"");
            highest = uid;
        }
        else if(uid < lowest) {
            NSCAssert(authoritative || lowest.sequence == uid.sequence || lowest.sequence -1 == uid.sequence, @"");
            lowest = uid;
        }
    }
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::canContain(const EventUID& uid) const {
    
	if(empty()) {
        return true;
    }

    if(containsEvent(uid)) {
        return true;
    }
    
    if(highest.sequence <= uid.sequence) {
        return highest.sequence == uid.sequence || highest.sequence +1 == uid.sequence;
    }
    else if(uid.sequence <= lowest.sequence) {
        return lowest.sequence == uid.sequence || lowest.sequence -1 == uid.sequence;
    }
    else {
        return false;
    }
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::containsEvent(const EventUID& uid) const {
    return !empty() && (lowest <= uid && uid <= highest);
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::containsEvent(int sequence, UIDRand random) const {
    return containsEvent(EventUID(sequence, random));
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
NSString *EventBlock::description() const {
    if(empty()) {
        return @"[]";
    }
    
    return [NSString stringWithFormat:@"[%@ - %@]", lowest.description(), highest.description()];
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::empty() const {
    return lowest == EventUID::UID_NONE;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::shouldMerge(const EventBlock& other) const {

    return internalShouldMerge(other) || other.internalShouldMerge(*this);
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::containsSequence(int seq) const {
    return !empty() && seq >= lowest.sequence && seq <= highest.sequence;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::internalShouldMerge(const EventBlock &other) const {
    
    if(empty() || other.empty()) {
        return false;
    }
    
    return containsEvent(other.lowest) || containsEvent(other.highest) || // contained
    lowest.sequence == other.highest.sequence +1 || // contiguous sequences
    lowest.sequence == other.highest.sequence; // overlapping sequences
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventUID EventBlock::getLowestEvent() const {
    return lowest;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventUID EventBlock::getHighestEvent() const {
    return highest;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::operator==(const EventBlock& other) const {
    return lowest == other.lowest && highest == other.highest;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlock::operator!=(const EventBlock& other) const {
    return ! operator==(other);
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlock::merge(const EventBlock& other) {
    lowest = std::min(lowest, other.lowest);
    highest = std::max(highest, other.highest);
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
const EventUID EventBlockContainer::STARTING_EVENT {1,0};


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::add(const EventUID& uid) {
    internalAdd(uid);
    hasGapCachedIsValid = false;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::internalAdd(const EventUID& uid) {

    for(auto it = blocks.begin(); it != blocks.end(); ++it) {
        EventBlock& bk = *it;
        
        // if it doesn't fit here, check if this should be inserted before, otherwise check next
        if(!bk.canContain(uid)) {
            
            if(bk.getLowestEvent() > uid) {
                // insert in this gap (it is a gap, no need to check additional merges)
                
                blocks.insert(it, EventBlock({uid}));
                return; // done
            }
            continue;
        }
        
        // add event to block
        bk.addEvent(uid, false);
        
        // did adding this event to the block allow me to merge with the next block?
        // because blocks are ordered, adding one event (that assumes no gaps in sequence)
        // can only cause this to merge with the next block as I already checked that the message
        // couldn't be merged with the previous, and adding one event can't make it grow more than 1 sequence number
        auto next = it;
        ++next;
        if(next != blocks.end()) {
            EventBlock& b2 = *next;
            if(bk.shouldMerge(b2)) {
                bk.merge(b2);
                blocks.erase(next);
            }
        }
        
        return; // done, quit here
    }
    
    // if I reached here, I got to the end of the list without finding a fit
    blocks.push_back(EventBlock({uid}));
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::add(const EventBlock& block) {
    internalAdd(block);
    hasGapCachedIsValid = false;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock EventBlockContainer::blockForEvent(const EventUID &uid) const
{
    auto it = std::find_if(blocks.cbegin(), blocks.cend(), [uid](EventBlock const &b){
        return b.containsEvent(uid);
    });
    return (it != blocks.cend()) ? *it : EventBlock();
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::internalAdd(const EventBlock& block) {
    
    // special case: if the block goes before the first block
    // then add it here
    if(blocks.empty()) {
        blocks.push_front(block);
        return;
    }
    
    for(auto it = blocks.begin(); it != blocks.end(); ++it) {
        
        EventBlock& bk = *it;
        
        // if I can't merge, check if this should be inserted before, otherwise check next
        if(!bk.shouldMerge(block)) {
            
            if(bk.getLowestEvent().sequence > block.getHighestEvent().sequence) {
                // insert into this gap (it is a gap, no need to check additional merges)
                blocks.insert(it, block);
                return; // we are done
            }
            continue;
        }
        
        // the merge might cause $bk to be mergeable with the next ones (if $block was big enough).
        // it can't be mergeable with the previous one because I already checked that $block could not
        // be merged with it, and I assume that all blocks in the list are separated
        bk.merge(block);
        
        // I will keep advancing the iterator as
        // long as I find blocks that I can merge. Then I will merge all of them at once.
        auto it2 = it;
        ++it2;
        for(; it2 != blocks.end() && bk.shouldMerge(*it2); ++it2) {
            bk.merge(*it2);
        }
        
        // roll back one to find the last mergeable
        --it2;
        
        // now it2 points to the next block after the last one that can be merged. Roll back 1, delete everything in between
        if(it2 != it) {
            blocks.erase(++it,++it2); // messed up $it
            return; // leave here as a reminder that $it is messed up
        }
        return;
    }
	
    // If I reached here, I got to the end of the list without finding a fit
    blocks.push_back(block);
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock EventBlockContainer::getGap(bool fromStart) const {
    
    if(blocks.empty()) {
        if(windowStart.empty() || windowEnd.empty()) {
            // how am I supposed to know?? no gap
            return EventBlock();
        }
        else {
            return EventBlock({windowStart, windowEnd});
        }
    }
    
    // I should treat 1.0 as an a special case, because it's not a literal 1.0 but any 1.x
    const bool isStartGenericOne = windowStart == STARTING_EVENT;
    
    // open start
    const bool hasStart = !windowStart.empty();
    // open end
    const bool hasEnd = !windowEnd.empty();

    // lowest in the collection
    const auto lowest = getLowestEvent();
    
    // "real" expected start. it might be 1.x
    auto realStart = hasStart ? windowStart : lowest;
    
    if(isStartGenericOne) {
        
        // if it's 1.x, and I have 1, replace. If I don't have one, keep 1.0 as 0 is guaranteed to be smaller than anything on the server
        if(isStartGenericOne && lowest.sequence == 1) {
            realStart = lowest;
        }
    }
    
    // real expected end
    const auto realEnd = hasEnd ? windowEnd : getHighestEvent();
    

    EventBlock gap;
    // am I looking for the lowest gap?
    if(fromStart) {
        return findLowestGap(realStart, realEnd);
    }
    else { // ! fromStart
        return findHighestGap(realStart, realEnd);
    }
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock EventBlockContainer::findLowestGap(const EventUID& start, const EventUID& end) const {
    
    // lowest in the container
    const auto lowest = getLowestEvent();
    
    // highest in the container
    const auto highest = getHighestEvent();
    
    // sanity checks
    NSCAssert(lowest <= highest, @"");
    if(start > end) {
        return EventBlock();
    }
    
    
	// is the start smaller than what I have? that's the first gap
    if(start < lowest) {
        return EventBlock({start, std::min(lowest, end)});
    }
    
    // is the start bigger than what I have? then it's start-end
    if(start > highest) {
        return EventBlock({start, end});
    }
    
    // scan for something after expected start, linearely, ascending
    for(auto it = blocks.begin(); it != blocks.end(); ++it) {
        const EventBlock& block = *it;
        
        // it's in this block
        if(block.containsEvent(start))
        {
            // is the expected ending also in this block?
            if(block.containsEvent(end)) {
                return EventBlock(); // we have everything!
            }
            else {
                // there's a gap. If this is not the last block, return the gap between this and the next.
                auto itNext = it;
                
                // look at the next one
                ++itNext;
                
                // there's no next, or the next is anyway bigger than realEnd, gap is end of this until real end
                if(itNext == blocks.end() || itNext->getLowestEvent() > end) {
                    return EventBlock({it->getHighestEvent(), end});
                }
                else {
                    // there's a block, smaller than end
                    return EventBlock({it->getHighestEvent(), itNext->getLowestEvent()});
                }
            }
        }
        else if(block.getHighestEvent() < start) {
            // this block is out of my window, ignore
            continue;
        }
        else {
            // not out of my window, but I'm not inside this block. Then there must be a gap between the start of the window and this block, bingo.
            return EventBlock({start, block.getLowestEvent()});
        }
        
    } // for
    
    NSCAssert(false, @"Should never get here");
    return EventBlock();
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventBlock EventBlockContainer::findHighestGap(const EventUID& start, const EventUID& end) const {
    
	// lowest in the container
    const auto lowest = getLowestEvent();
    
    // highest in the container
    const auto highest = getHighestEvent();
    
    // sanity checks
    NSCAssert(lowest <= highest, @"");
    if(start > end) {
        return EventBlock();
    }
    
    
	// is the end bigger than what I have? that's the first gap
    if(end > highest) {
        return EventBlock({end, std::max(highest, start)});
    }
    
    // is the end smaller than what I have? then it's start-end
    if(end < lowest) {
        return EventBlock({start, end});
    }
    
    // scan for something after expected start, linearely, ascending
    for(auto it = blocks.crbegin(); it != blocks.crend(); ++it) {
        const EventBlock& block = *it;
        
        // it's in this block
        if(block.containsEvent(end))
        {
            // is the expected start also in this block?
            if(block.containsEvent(start)) {
                return EventBlock(); // we have everything!
            }
            else {
                // there's a gap. If this is not the first block, return the gap between this and the next.
                auto itNext = it;
                
                // look at the next one
                ++itNext;
                
                // there's no next, or the next is anyway smaller than start, gap is start of this until real start
                if(itNext == blocks.rend() || itNext->getHighestEvent() < start) {
                    return EventBlock({it->getLowestEvent(), start});
                }
                else {
                    // there's a block, bigger than start
                    return EventBlock({it->getLowestEvent(), itNext->getHighestEvent()});
                }
            }
        }
        else if(block.getLowestEvent() > end) {
            // this block is out of my window, ignore
            continue;
        }
        else {
            // not out of my window, but I'm not inside this block. Then there must be a gap between the end of the window and this block, bingo.
            return EventBlock({end, block.getHighestEvent()});
        }
        
    } // for
    
    NSCAssert(false, @"Should never get here");
    return EventBlock();
}




//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlockContainer::hasEvent(const EventUID& uid) const {
    
    for(auto& bk : blocks) {
        if(bk.containsEvent(uid)) {
            return true;
        }
    }
    
    return false;
	
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventUID EventBlockContainer::getLowestEvent()const {
    if(blocks.empty()) {
        return EventUID::UID_NONE;
    }
	
    return blocks.begin()->getLowestEvent();
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
EventUID EventBlockContainer::getHighestEvent()const {
    
	if(blocks.empty()) {
        return EventUID::UID_NONE;
    }
    
    return (--blocks.end())->getHighestEvent();
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::setWindow(const EventUID& lower, const EventUID& higher) {
    
	// sanity. to be safe, also return no gap
    if(!higher.empty() && !lower.empty()) {
        NSCAssert(lower <= higher, @"start should be < end");
    }
    
    windowEnd = higher;
    windowStart = lower;
    
    // invaludate cache
    hasGapCachedIsValid = false;

}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlockContainer::empty() const {
	return blocks.empty();
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::setWindowUpperBound(const EventUID &bound) {
	windowEnd = bound;
    hasGapCachedIsValid = false;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
void EventBlockContainer::setWindowLowerBound(const EventUID &bound) {
	windowStart = bound;
    hasGapCachedIsValid = false;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
bool EventBlockContainer::hasGap() const {
    if(!hasGapCachedIsValid) {
        auto gap = getGap(true);
        hasGapCached = !gap.empty();
    }
    return hasGapCached;
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
namespace {
    void copyEventBlockBytes(EventUID block, unsigned char* destination, size_t& offset) {
        memcpy(destination + offset, &block.sequence, sizeof(EventUID::sequence));
        memcpy(destination + offset + sizeof(EventUID::sequence), &block.random, sizeof(EventUID::random));
        offset += EVENT_UID_SIZE;
    }
}

NSData *EventBlockContainer::serialize() const {
    
    // a block is 2 event IDs
    std::vector<unsigned char> mem(blocks.size() * BLOCK_SIZE, 0);
    size_t count = 0;
    for(EventBlock b : blocks) {
        EventUID lowest = b.getLowestEvent();
        EventUID highest = b.getHighestEvent();
        
        copyEventBlockBytes(lowest, mem.data(), count);
        copyEventBlockBytes(highest, mem.data(), count);
    }
    
    return [NSData dataWithBytes:(void *)mem.data() length:mem.size()];
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
namespace {
    EventUID eventUIDFromBytes(unsigned char* data, size_t& offset) {
        int sequence = 0;
        UIDRand random = 0;
        memcpy(&sequence, data + offset, sizeof(EventUID::sequence));
        memcpy(&random, data + offset + sizeof(EventUID::sequence), sizeof(EventUID::random));
        offset += EVENT_UID_SIZE;
        return EventUID(sequence, random);
    }
}

EventBlockContainer::EventBlockContainer(NSData *serializedData)
{
    NSCAssert(serializedData.length % BLOCK_SIZE == 0, @"Data does not seem to contain blocks");
    const size_t numBlocks = serializedData.length / BLOCK_SIZE;
    unsigned char* data = (unsigned char*) [serializedData bytes];
    
    size_t offset = 0;
    for(size_t i = 0; i < numBlocks; ++i) {
        
        const EventUID low = eventUIDFromBytes(data, offset);
        const EventUID high = eventUIDFromBytes(data, offset);
        EventBlock block({low, high});
        add(block);
    }
}


//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
std::pair<EventUID, EventUID> EventBlockContainer::getWindow()const {
    
	return std::make_pair(windowStart, windowEnd);
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
NSString * EventBlockContainer::description() const {
	
    NSMutableArray *components = [NSMutableArray array];
    for(auto b : blocks) {
        [components addObject:b.description()];
    }
    NSMutableString *description = [NSMutableString stringWithString:@"(Window: "];
    if (windowStart.empty()) {
        [description appendString:@"*"];
    } else {
        [description appendString:windowStart.description()];
    }
    [description appendString:@", "];
    if (windowEnd.empty()) {
        [description appendString:@"*"];
    } else {
        [description appendString:windowEnd.description()];
    }
    [description appendFormat:@") [%@]", [components componentsJoinedByString:@", "]];
    return description;
}

/////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////
bool EventBlockContainer::operator==(const EventBlockContainer& other) const {
    return blocks == other.blocks
        && windowStart == other.windowStart
        && windowEnd == other.windowEnd;
}


