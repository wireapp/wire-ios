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


#include <vector>
#include <list>
#include <sstream>

#include "EventUID.h"
#import <Foundation/Foundation.h>



/**
 A list of contiguous event UIDs
 
 This class keeps track of contiguous blocks of UIDs.
 
 We assume that EventUIDs have an ordering (reflecting the backend database order) We don't assume that they are contiguous, on the sequence
 number nor on the random part.
 
 We keep track of the extremes of a block
 e.g.
 [5.4325 ... ( I know that here we have all 6,7,8,9, so I don't save them) ... 10.325]
 
 This might cause some messages to be lost in case the messages have duplicated sequence numbers.
 If the push channel goes down, we will never know that we did not receive them.
 However in order to have be sure to have them (= not trusting the push channel) we will need to constantly polling backend, hence defying
 the purpose of the push channel.
 It was discussed with BE that this is acceptable as we expect very few messages to have duplicated numbers.
 
 */

class EventBlock {

public:
    
    EventBlock() = default;
    EventBlock(const EventBlock& other);
    
    /// creates a event block from the UID in the list. The list is assumed to be authoritative
    EventBlock(const std::vector<EventUID>& list);
    
    /// gets the highest event
    EventUID getHighestEvent() const;
    
    /// gets the lowest event
    EventUID getLowestEvent() const;
    
    /// Returns whether this event belongs in this group (already there, or within +/- 1 sequence away
    bool canContain(const EventUID& uid) const;
    
    /// adds the event to the block. If authoritative, don't assert if it can't contain it
    void addEvent(const EventUID& uid, bool authoritative);
    
    /// whether the event UID is included in this block
    bool containsEvent(const EventUID& uid) const;
    bool containsEvent(int sequence, UIDRand random) const;
    
    /// returns a debug representation
    NSString *description() const;
    
    /// returns true if the other block should merge with this one (because some boundaries are shared)
    bool shouldMerge(const EventBlock& other) const;
    
    /// merges the other block into this one
    void merge(const EventBlock& other);
    
    /// returns whether there is no UID in this block
    bool empty() const;
    
    bool operator==(const EventBlock& other) const;
    bool operator!=(const EventBlock& other) const;
    
private:

    /// the lowest UIDs
    EventUID lowest = EventUID::UID_NONE;
    
    /// the highest UIDs
    EventUID highest = EventUID::UID_NONE;
    
    /// returns true if the other block should merge with this one. Do not check the other way round
    bool internalShouldMerge(const EventBlock& other) const;
    
    /// returns true if the sequence number is contained (not on edge)
    bool containsSequence(int seq) const;
    
};



/**
 An ordered list of EventBlocks
 
 We don't assume that sequence numbers are contiguous, but we expect them to be most of the time. Hence if we see a gap in sequence
 numbers, we mark it as a gap until a poll to the backend tells us that there was indeed a gap. In this case we fill the gap on our side 
 and continue as if it wasn't there.
 
 Filling a gap is achieved by adding an EventBlock with a range that includes that gap.
 
 */
class EventBlockContainer {
public:
    
    EventBlockContainer() {}
    
    EventBlockContainer(NSData *serializedData);
    
    /// the default start event UID, {1,0}
    static const EventUID STARTING_EVENT;
    
    /// Adds an event to the container. If it fits in a block, it will be inserted in that block, otherwise it will create a new block
    void add(const EventUID& uid);
    
    /// Adds a block to the container. If it can be merged with a block, it will be merged, otherwise it will be isolated
    void add(const EventBlock& block);
    
    /// Returns the block the given event is in, or an empty block.
    EventBlock blockForEvent(const EventUID &uid) const;
    
    /**
     returns a gap, if any. If none, returns an empty EventBlock
     @param ascending if true, will return the lowest gap in ascending EventUID order. If false, will return the highest one
     @param expectedStart if not empty, assume this uid is the first one. Otherwise, assume the lowest of the first block is the first uid
     @param expectedLast if not empty, assume this is the last uid. Otherwise, assume the the highest of the last block is the last uid
     @pre expectedStart <= expectedLast
     */
    EventBlock getGap(bool ascending) const;
    
    /// returns whether there is a gap
    bool hasGap() const;
    
    /// sets the current eventUID window to consider (extremes included)
    void setWindow(const EventUID& first, const EventUID& last);
    
    /// sets the window upper bound
    void setWindowUpperBound(const EventUID& bound);
    
    /// sets the window lower bound
    void setWindowLowerBound(const EventUID& bound);
    
    /// Returns true if this event is present in the container
    bool hasEvent(const EventUID& uid) const;
    
    /// gets the lowest EventUID in the container
    EventUID getLowestEvent() const;

    /// gets the highest EventUID in the container
    EventUID getHighestEvent() const;
    
    /// returns whether there is any block in the container
    bool empty() const;
    
    /// gets the current window
    std::pair<EventUID, EventUID> getWindow() const;

    /// returns a debug string
    NSString *description() const;
    
    /// comparison
    bool operator==(const EventBlockContainer& other) const;
    
    /// serialization
    NSData *serialize() const;
    
private:
    
    /// ordered (ascending) list of blocks. It is ordered because we guarantee that if two blocks overlap, we will merge them
    std::list<EventBlock> blocks;
    
    /// finds the lowest gap between the two events, inside the current window (if the gap is outside of the window, it will not be returned)
    EventBlock findLowestGap(const EventUID& start, const EventUID& end) const;
    
    /// finds the highest gap between the two events, inside the current window (if the gap is outside of the window, it will not be returned)
    EventBlock findHighestGap(const EventUID& start, const EventUID& end) const;
    
    /// the lower end of the window (inclusive)
    EventUID windowStart = STARTING_EVENT;
    
    /// the higher end of the window (inclusive)
    EventUID windowEnd = EventUID::UID_NONE;
    
    /// whether the hasGap value is valid (or need to be refreshed)
    mutable bool hasGapCachedIsValid { true };
    
    /// whether we have a gap or not. Cached.
    mutable bool hasGapCached { false };
    
    /// adds internally (not updating the cache)
    void internalAdd(const EventUID& uid);
    
    /// adds internally (not updating the cache)
    void internalAdd(const EventBlock& block);

};
