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


#import <ZMTesting/ZMTesting.h>

#import "EventBlock.h"
#import <algorithm>
#import <memory>
#import <cstdlib>
#import <iostream>
#import <random>


#define ASSERT_EQ(a, b) XCTAssertEqual(a, b)
#define ASSERT_TRUE(a) XCTAssertTrue(a)
#define ASSERT_FALSE(a) XCTAssertFalse(a)
#define ASSERT_NE(a, b) XCTAssertNotEqual(a, b)
#define ASSERT_LE(a, b) XCTAssertTrue(a <= b)
#define ASSERT_LT(a, b) XCTAssertTrue(a < b)
#define ASSERT_GE(a, b) XCTAssertTrue(a >= b)
#define ASSERT_GT(a, b) XCTAssertTrue(a > b)

#define SCOPED_TRACE(a)
#define ABORT_ON_FAILURE()


@interface ZMEventBlockTest : ZMTBaseTest
@end


static bool const SPAM_A_LOT = false;


@implementation ZMEventBlockTest



// used to test EventBlockContainer
struct EventOrBlock {
    
    EventUID event;
    EventBlock block;
    
    EventOrBlock(const EventBlock& bl) : block(bl) {}
    EventOrBlock(const EventUID& evt) : event(evt) {}
};

- (void)checkEventBlockContainer:(const std::vector<EventOrBlock>&)data expectedGaps:(const std::vector<EventBlock>&)expectedGaps container:(std::shared_ptr<EventBlockContainer>)outContainer;
{
    static int testN = 0;
    
    if(!outContainer) {
        outContainer = std::make_shared<EventBlockContainer>();
    }
    
    // keep track of max/min at each step
    EventUID min = outContainer->getLowestEvent();
    EventUID max = outContainer->getHighestEvent();
    
    if(SPAM_A_LOT) {
        std::cout << "\n\nTEST " << testN++ << "\nTesting with insertion: ";
        std::cout << "Current container is" << outContainer->description().UTF8String << std::endl;
    }
    
    // for each new insertion
    for(auto d : data) {
        
        std::vector<EventUID> evts;
        
        if(SPAM_A_LOT) {
            std::cout << "Inserting ";
        }
        // add to container - EVENT
        if(!d.event.empty()) {
            evts.push_back(d.event);
            outContainer->add(d.event);
            if(SPAM_A_LOT) {
                std::cout << d.event.description().UTF8String << ", ";
            }
        }
        
        // add to container - BLOCK
        else if(!d.block.empty()) {
            evts.push_back(d.block.getLowestEvent());
            evts.push_back(d.block.getHighestEvent());
            
            outContainer->add(d.block);
            if(SPAM_A_LOT) {
                std::cout << d.block.description().UTF8String << ", ";
            }
        }
        
        // update max/min
        for(auto e : evts) {
            if(min.empty()) {
                min = e;
                max = e;
            }
            else {
                if(e < min) {
                    min = e;
                }
                if(e > max) {
                    max = e;
                }
            }
            
            // check that I have what I added
            ASSERT_TRUE(outContainer->hasEvent(e));
        }
        
        if(SPAM_A_LOT) {
            std::cout << outContainer->description().UTF8String << std::endl;
        }
        
        // check that I have the right max/min
        ASSERT_EQ(min, outContainer->getLowestEvent());
        ASSERT_EQ(max, outContainer->getHighestEvent());
    }
    
    if(SPAM_A_LOT) {
        std::cout << std::endl;
        std::cout << "Testing with expected gaps ";
        for(auto g : expectedGaps) {
            std::cout << g.description().UTF8String << ", ";
        }
        std::cout << std::endl;
        std::cout << "Current container is" << outContainer->description().UTF8String << std::endl;
    }
    
    [self checkGapsInContainer:*outContainer expectedGaps:expectedGaps ascending:true];
    [self checkGapsInContainer:*outContainer expectedGaps:expectedGaps ascending:true];
    
    {
//        SCOPED_TRACE("Testing serialization");
//        std::vector<uint8_t> serialized;
//        outContainer->serialize(serialized);
//        
//        ASSERT_LT(serialized.size(), 100000);
//        
//        EventBlockContainer deserialized;
//        deserialized.deserialize(serialized);
//        
//        ASSERT_EQ(*outContainer, deserialized);
//        
//        ZVector<uint8_t> serializedProof;
//        deserialized.serialize(serializedProof);
//        ASSERT_EQ(serialized, serializedProof);
//        
//        ASSERT_EQ(deserialized.toDebugString(), outContainer->toDebugString());
    }
    
}

// Tests that the container has the gaps I expect. Also tests filling those gaps
// all passed by value so I have private copies that I can mess up
- (void)checkGapsInContainer:(EventBlockContainer)container expectedGaps:(std::vector<EventBlock>)expectedGaps ascending:(bool)ascending
{
    // now check expected gaps. Sort them ascending first
    std::sort(expectedGaps.begin(), expectedGaps.end(), [ascending](const EventBlock& b1, const EventBlock&b2) {
        if(ascending) {
            return b1.getLowestEvent() < b2.getLowestEvent();
        }
        else {
            return b1.getHighestEvent() > b2.getHighestEvent();
        }
    });
    
    for(auto gap : expectedGaps) {
        auto theGap = container.getGap(ascending);
        ASSERT_EQ(theGap, gap);
        ASSERT_TRUE(container.hasGap());
        
        // now fill the gap, so I don't find it later
        container.add(gap);
    }
    
    // all the gaps should be filled
    ASSERT_TRUE(container.getGap(true).empty());
    ASSERT_FALSE(container.hasGap());
}

- (void)checkEventBlockMerge:(bool)shouldFail block1:(EventBlock)b1 block2:(const EventBlock&)b2
{
    ASSERT_NE(shouldFail, b1.shouldMerge(b2));
    ASSERT_NE(shouldFail, b2.shouldMerge(b1));
    
    if(!shouldFail) {
        EventUID low = std::min(b1.getLowestEvent(), b2.getLowestEvent());
        EventUID high = std::max(b1.getHighestEvent(), b2.getHighestEvent());
        
        b1.merge(b2);
        
        ASSERT_EQ(low, b1.getLowestEvent());
        ASSERT_EQ(high, b1.getHighestEvent());
    }
}


///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void)checkEventBlockAdding:(const std::vector<EventUID>&)UIDsToAdd expectFailure:(bool)expectFailure authoritative:(bool)authoritative outBlock:(std::shared_ptr<EventBlock>)outBlock
{
    if(!outBlock) {
        outBlock = std::make_shared<EventBlock>();
    }
    
    EventUID min, max;
    
    for(auto& uid : UIDsToAdd) {
        
        // track min/max for later
        if(min == EventUID::UID_NONE || uid < min) {
            min = uid;
        }
        if(min == EventUID::UID_NONE || uid > max) {
            max = uid;
        }
        
        // is it supposed to fail?
        const bool shouldFail = uid == *(--UIDsToAdd.end()) && expectFailure; // it was the last one and I was expecting it to fail
        
        if(!authoritative) {
            XCTAssertTrue(shouldFail != outBlock->canContain(uid), @"UID %@", uid.description());
        }
        
        // insert
        if (shouldFail) {
            XCTAssertThrows(outBlock->addEvent(uid, authoritative));
        } else {
            outBlock->addEvent(uid, authoritative);
            XCTAssertTrue(outBlock->containsEvent(uid), @"Block doesn't seem to contain event %@", uid.description());
        }
    }
    
    if(!expectFailure) {
        ASSERT_EQ(min, outBlock->getLowestEvent());
        ASSERT_EQ(max, outBlock->getHighestEvent());
    }
}

static void fillRandomVector(std::vector<EventUID>& outvector, size_t number, unsigned int seed) {
    
    std::mt19937_64 generator(seed);
    std::uniform_int_distribution<int> seqSistribution(1, 100);
    std::uniform_int_distribution<unsigned long> rndDistribution(1, 1000);
    
    outvector.clear();
    outvector.reserve(number);
    
    for(size_t i = 0; i < number; ++i) {
        outvector.emplace_back(seqSistribution(generator), rndDistribution(generator));
    }
}

static void fillRandomVector(std::vector<EventBlock>& outvector, size_t number, unsigned int seed) {
    
    std::mt19937_64 generator(seed);
    std::uniform_int_distribution<int> seqSistribution(1, 100);
    std::uniform_int_distribution<unsigned long> rndDistribution(1, 1000);
    
    outvector.clear();
    outvector.reserve(number);
    
    for(size_t i = 0; i < number; ++i) {
        outvector.emplace_back(EventBlock ({{ seqSistribution(generator), rndDistribution(generator) }, { seqSistribution(generator), rndDistribution(generator) }}));
    }
}



- (void)testThatInsertingIntoEventBlocksWorks
{
    
    std::vector<EventUID> list {
        {43, 3},
        {8, 43},
        {43, 321},
        {10, 8},
        {5, 5}
    };
    
    {
        EventBlock b1;
        ASSERT_TRUE(b1.empty());
        for(auto uid : list) {
            b1.addEvent(uid, true);
        }
        ASSERT_EQ(b1.getLowestEvent(), EventUID(5,5));
        ASSERT_EQ(b1.getHighestEvent(), EventUID(43, 321));
        
        EventBlock b2(list);
        ASSERT_EQ(b2.getLowestEvent(), EventUID(5,5));
        ASSERT_EQ(b2.getHighestEvent(), EventUID(43, 321));
        
        ASSERT_EQ(b1, b2);
        
        EventBlock b3;
        b3.addEvent({5,5}, false);
        
        ASSERT_NE(b1, b3);
    }
    
    {
        SCOPED_TRACE("Part 2");
        EventBlock b1;
        ASSERT_TRUE(b1.empty());
        static const size_t START = 1231456;
        static const int MAX_SEQ = 10;
        static const size_t STEP = 100000;
        
        
        for(size_t j = START; j < START + STEP; ++j) {
            for(int i = 1; i <= MAX_SEQ; ++i) {
                b1.addEvent({i, j}, false);
                
                ASSERT_TRUE(b1.containsEvent({i, j}));
            }
        }
        ASSERT_EQ(b1.getLowestEvent(), EventUID(1,START));
        ASSERT_EQ(b1.getHighestEvent(), EventUID(MAX_SEQ, START + STEP -1));
    }
}


- (void)testThatInsertingIntoEventBlocksWorks_2
{
    // stop catching asserts, I want to manually control them in this test
    
    {
        // this block should succeed
        std::shared_ptr<EventBlock> block = std::make_shared<EventBlock>();
        [self checkEventBlockAdding:{
            {10, 2},
            {11, 3},
            {12, 3},
            {10, 3},
            {9, 8},
            {12, 5},
        }  expectFailure:false authoritative:false outBlock:block];
        
        ASSERT_FALSE(block->containsEvent(EventUID(5, 3124235)));
        ASSERT_FALSE(block->containsEvent(EventUID(9, 1)));
        ASSERT_TRUE(block->containsEvent(EventUID(11, 53455345)));
        ASSERT_TRUE(block->containsEvent(EventUID(9,8)));
        ASSERT_TRUE(block->containsEvent(EventUID(12,3)));
        ASSERT_FALSE(block->containsEvent(EventUID(12,9)));
    }
    
    {
        [self checkEventBlockAdding:{
            {10, 325},
            {8, 312}, // fail because 8 < 10-1
        } expectFailure:true authoritative:false outBlock:nullptr];
    }

    {
        [self checkEventBlockAdding:{
            {500, 4234},
            {498, 23}, // fail because 499 + 1< 500
        } expectFailure:true authoritative:false outBlock:nullptr];
    }

    {
        [self checkEventBlockAdding:{
            {500, 4234},
            {499, 23},
            {510, 23} // fail because 510 > 500+1
        } expectFailure:true authoritative:false outBlock:nullptr];
    }
    
    {
        // repetitions
        [self checkEventBlockAdding:{
            {10, 312},
            {10, 8},
            {10, 3},
            {10, 5},
            {10, 8},
            {9, 213},
            {10, 45},
        } expectFailure:false authoritative:false outBlock:nullptr];
    }
    
    {
        // authoritative, should not fail regardless of gaps
        [self checkEventBlockAdding:{
            {5, 10},
            {20, 40},
            {8, 23},
            {5,1},
            {20, 40},
        } expectFailure:false authoritative:true outBlock:nullptr];
    }
}

- (void)testThatEventBlocksCanBeMerged
{
    {
        // totally contained
        [self checkEventBlockMerge:false block1:EventBlock({{10, 1}, {45, 234}}) block2:EventBlock({{3, 5435}, {100, 100}})];
    }
    
    {
        // partially contained, dx
        [self checkEventBlockMerge:false block1:EventBlock({{10, 1}, {45, 234}}) block2:EventBlock({{34, 54}, {100, 100}})];
    }
    
    {
        // partially contained, sx
        [self checkEventBlockMerge:false block1:EventBlock({{10, 1}, {45, 234}}) block2:EventBlock({{6, 54}, {32, 100}})];
    }
    
    {
        // partially contained, sx same sequence
        [self checkEventBlockMerge:false block1:EventBlock({{10, 1}, {45, 234}}) block2:EventBlock({{6, 54}, {10, 100}})];
    }
    
    {
        // equal
        [self checkEventBlockMerge:false block1:EventBlock({{32, 3}, {30, 5}}) block2:EventBlock({{30, 5}, {32, 3}})];
    }
    
    {
        // disjoint, != sequence
        [self checkEventBlockMerge:true block1:EventBlock({{1,1}, {10,10}}) block2:EventBlock({{23, 321}, {24, 432}})];
    }
    
    {
        // disjoint, same sequence
        [self checkEventBlockMerge:false block1:EventBlock({{1,1}, {10,10}}) block2:EventBlock({{23, 321}, {10, 432}})];
    }
}



- (void)testUsingEventBlockContainerForBasicOperations
{
    {
        SCOPED_TRACE("From known bug - 1");
        EventBlockContainer ebc;
        ebc.add({47, 755});
        ebc.add({59, 109});
        
        ASSERT_LT(ebc.getLowestEvent(), ebc.getHighestEvent());
    }
    
    {
        SCOPED_TRACE("From known bug - 2");
        EventBlockContainer ebc;
        ebc.add({{{1, 755}, {67, 543}}});
        ebc.add({68, 109});
        
        ASSERT_FALSE(ebc.hasGap());
    }
    
    {
        SCOPED_TRACE("Test no gaps when empty");
        EventBlockContainer container;
        
        ASSERT_TRUE(container.getGap(true).empty());
        ASSERT_TRUE(container.getGap(false).empty());
    }
    
    {
        SCOPED_TRACE("Testing base operation and windows");
        std::vector<EventBlock> testEdges {
            {}, // empty
            {{{1,0},{34,4234}}},
            {{{424,324235},{42342,234234}}},
            {{{10,10},{10,10}}},
        };
        
        {
            SCOPED_TRACE("Empty container");
            
            // test that changing the window doesn't mess it up, empty
            EventBlockContainer cc;
            
            for(EventBlock edge : testEdges) {
                if(!edge.empty()) {
                    cc.setWindow(edge.getLowestEvent(), edge.getHighestEvent());
                }
                ASSERT_TRUE(cc.empty());
                ASSERT_EQ(cc.getLowestEvent(), EventUID::UID_NONE);
                ASSERT_EQ(cc.getHighestEvent(), EventUID::UID_NONE);
            }
        }
        
        {
            SCOPED_TRACE("One event (one block)");
            
            // test that changing the window doesn't mess it up, one event
            EventBlockContainer cc;
            
            EventUID uid {10,5};
            cc.add(uid);
            for(EventBlock edge : testEdges) {
                if(!edge.empty()) {
                    cc.setWindow(edge.getLowestEvent(), edge.getHighestEvent());
                }
                ASSERT_FALSE(cc.empty());
                ASSERT_EQ(cc.getLowestEvent(), uid);
                ASSERT_EQ(cc.getHighestEvent(), uid);
            }
        }
        
        {
            SCOPED_TRACE("Two blocks");
            
            // test that changing the window doesn't mess it up, one event
            EventBlockContainer cc;
            
            EventBlock b1 {{{10,5},{5,432}}};
            EventBlock b2 {{{40, 4324}, {2342,32}}};
            
            EventUID max = std::max(b1.getHighestEvent(), b2.getHighestEvent());
            EventUID min = std::min(b1.getLowestEvent(), b2.getLowestEvent());
            
            cc.add(b1);
            cc.add(b2);
            
            for(EventBlock edge : testEdges) {
                if(!edge.empty()) {
                    cc.setWindow(edge.getLowestEvent(), edge.getHighestEvent());
                    ASSERT_EQ(cc.getWindow().first, edge.getLowestEvent());
                    ASSERT_EQ(cc.getWindow().second, edge.getHighestEvent());
                }
                ASSERT_FALSE(cc.empty());
                ASSERT_EQ(cc.getLowestEvent(), min);
                ASSERT_EQ(cc.getHighestEvent(), max);
            }
        }
    }
}


- (void)testUsingEventBlockContainerForInsertionAndGaps_1
{
    std::vector<EventUID> evt;
    std::vector<EventBlock> blk;
    fillRandomVector(evt, 10000, 321);
    fillRandomVector(blk, 10000, 423);
    {
        EventBlockContainer cc;
        
        for(auto& uid : evt) {
            cc.add(uid);
            ASSERT_TRUE(cc.hasEvent(uid));
            ASSERT_NE(cc.hasGap(), cc.getGap(false).empty());
        }
        
        // recheck
        for(auto& uid : evt) {
            ASSERT_TRUE(cc.hasEvent(uid));
        }
        ASSERT_NE(cc.hasGap(), cc.getGap(false).empty());
    }
    
    {
        EventBlockContainer cc;
        
        for(auto& b : blk) {
            cc.add(b);
        }
        
        for(auto& uid : evt) {
            cc.add(uid);
            ASSERT_TRUE(cc.hasEvent(uid));
            ASSERT_NE(cc.hasGap(), cc.getGap(false).empty());
        }
        
        // recheck
        for(auto& uid : evt) {
            ASSERT_TRUE(cc.hasEvent(uid));
        }
        ASSERT_NE(cc.hasGap(), cc.getGap(false).empty());
    }
    
    {
        EventBlockContainer cc;
        EventUID e1 {1, 10}, e2 {5,54}, e3 {5,55}, e4 {5,100};
        cc.setWindow({1,0}, e4);
        
        cc.add({{e3, e4}});
        cc.add({{e1, e2}});
        
        
        ASSERT_TRUE(cc.getGap(true).empty());
        ASSERT_NE(cc.getGap(true).empty(), cc.hasGap());
    }
}

- (void)testUsingEventBlockContainerForInsertionAndGaps_2
{
    
    /*
     Graphic representation of the container situation, in order of insertion:
     0:(1,0)
     1:                                          (45,23)
     2:           (10,5)------------------(20,50)
     3:                    (15,30)----------------------(60,20)
     4:       (5,1)----------------(16,3)
     5:   (4,8)
     6:                                                 (60,30)--------------(70,1)
     7:                                                                                            (85,20)-(95,30)
     8:                                                                            (72,23)--(80,80)
     9:                                                                         (71,5)
     10:(1,5)-------------------------------------------------------------------------------------------------------(100,324)
     // here gaps should be filled, lower (1,5), higher (80,80)
     */
    
    SCOPED_TRACE("Block 1 - no window");
    std::shared_ptr<EventBlockContainer> cc = std::make_shared<EventBlockContainer>();
    
    const EventUID e1(45, 23),
    b2e1(10,5), b2e2(20,50),
    b3e1(15,30), b3e2(60,20),
    b4e1(5,1), b4e2(16,3),
    e5(4,8),
    b6e1(60,30), b6e2(70,1),
    b7e1(85,20), b7e2(95, 30),
    b8e1(72,23), b8e2(80,80),
    e9(71,5),
    b10e1(1,5), b10e2(100,324);
    
    const EventBlock b2({b2e1, b2e2}),
    b3({b3e1, b3e2}),
    b4({b4e1, b4e2}),
    b6({b6e1, b6e2}),
    b7({b7e1, b7e2}),
    b8({b8e1, b8e2}),
    b10({b10e1, b10e2});
    
    // no gaps, it's empty
    [self checkEventBlockContainer:{} expectedGaps:{} container:cc];
    
    const EventUID start = EventBlockContainer::STARTING_EVENT;
    
    {
        SCOPED_TRACE("A1");
        const EventBlock gap1({start,e1});
        [self checkEventBlockContainer:{ {e1} } expectedGaps:{ gap1 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A2");
        const EventBlock gap1({start, b2e1}), gap2({b2e2, e1});
        [self checkEventBlockContainer:{ {b2} } expectedGaps:{ gap1, gap2 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A3");
        const EventBlock gap1({start, b2e1});
        [self checkEventBlockContainer:{ {b3} } expectedGaps:{ gap1 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A4");
        const EventBlock gap1({start, b4e1});
        [self checkEventBlockContainer:{ {b4} } expectedGaps:{ gap1 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A5");
        const EventBlock gap1({start, e5});
        [self checkEventBlockContainer:{ {e5} } expectedGaps:{ gap1 } container:cc];
    }
    
    {
        SCOPED_TRACE("A5 - repeated");
        const EventBlock gap1({start, e5});
        [self checkEventBlockContainer:{ {e5} } expectedGaps:{ gap1 } container:cc];
    }
    
    {
        SCOPED_TRACE("A6");
        const EventBlock gap1({start, e5});
        [self checkEventBlockContainer:{ {b6} } expectedGaps:{ gap1 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A7");
        const EventBlock gap1({start, e5}), gap2({b6e2, b7e1});
        [self checkEventBlockContainer:{ {b7} } expectedGaps:{ gap1, gap2 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A7 - repeated");
        const EventBlock gap1({start, e5}), gap2({b6e2, b7e1});
        [self checkEventBlockContainer:{ {b7} } expectedGaps:{ gap1, gap2 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A8");
        const EventBlock gap1({start, e5}), gap2({b6e2, b8e1}), gap3({b8e2, b7e1});
        [self checkEventBlockContainer:{ {b8} } expectedGaps:{ gap1, gap2, gap3 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A9");
        const EventBlock gap1({start, e5}), gap2({b8e2, b7e1});
        [self checkEventBlockContainer:{ {e9} } expectedGaps:{ gap1, gap2 } container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A10");
        [self checkEventBlockContainer:{ {b10} } expectedGaps:{} container:cc];
        ASSERT_EQ(cc->getHighestEvent(), b10e2);
        ASSERT_EQ(cc->getLowestEvent(), b10e1);
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("All at once, different order 1");
        [self checkEventBlockContainer:{ {b4, b2, b3, e1, e5, b8, b7, b6, b10, e9} } expectedGaps:{} container:nullptr];
        ASSERT_EQ(cc->getHighestEvent(), b10e2);
        ASSERT_EQ(cc->getLowestEvent(), b10e1);
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("All at once, different order 2");
        [self checkEventBlockContainer:{ {b10,  b3, b4,  b2,  e5,  b6,  e1,  b8,  e9,  b7} } expectedGaps:{} container:nullptr];
        ASSERT_EQ(cc->getHighestEvent(), b10e2);
        ASSERT_EQ(cc->getLowestEvent(), b10e1);
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("All at once, different order 3");
        [self checkEventBlockContainer:{ {e9,  b10,  b2,  b7,  e1,  b8,  b3, b4,  b6,  e5} } expectedGaps:{} container:nullptr];
        ASSERT_EQ(cc->getHighestEvent(), b10e2);
        ASSERT_EQ(cc->getLowestEvent(), b10e1);
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("Adding the same elements multiple times");
        [self checkEventBlockContainer:{ {e9,  b10,  b2,  b7,  e1,  b8,  b3, b4,  b8, b6,  e9, e9, e5, b6,  e1,  b8,  e9,  b7, b4, b2, b3, e1, e5, b8, b7} } expectedGaps:{} container:nullptr];
        ASSERT_EQ(cc->getHighestEvent(), b10e2);
        ASSERT_EQ(cc->getLowestEvent(), b10e1);
        ABORT_ON_FAILURE();
    }
}


- (void)testUsingEventBlockContainerForInsertionAndGapsWithWindow
{
    /*
     Initial window (10,10) - (60,90)
     Graphic representation of the container situation, in order of insertion:
     0:                          |w                                 w|
     1:       (4,542)--(8,312)   |w                                 w|
     2:                          |w    (23, 42)--(33,423)           w|
     3:                          |w                                 w| (70,213)
     4:    (3,32)----------------|w------------------------(40,32)  w|
     5: |w                                                                      w|        // changing window to (2,1) - (80,80)
     6:                                |w                         w|                      // changin window to (23,100) - (50,30)
     7:  |w                                                               w|              // changing window to (3,1) - (70,215)
     8: |w|                                                                               // changing window to (2,1) - (2,3)
     9: |w|                                                                               // changing window to (2,2) - (2,2)
     10:                                                                 |ww|             // changing window to (70, 200) - (70, 213)
     */
    
    SCOPED_TRACE("Block 2 - window");
    std::shared_ptr<EventBlockContainer> cc = std::make_shared<EventBlockContainer>();
    
    const EventUID w1e1(10,10), w1e2(60,90),
    b1e1(4,543), b1e2(8,312),
    b2e1(23, 43), b2e2(33, 423),
    e3(70,213),
    b4e1(3,32), b4e2(40,32),
    w5e1(2,1), w5e2(80,80),
    w6e1(23,100), w6e2(50,30),
    w7e1(3,1), w7e2(70,215),
    w8e1(2,1), w8e2(2,3),
    w9e1(2,2), w9e2(2,2),
    w10e1(70,200), w10e2(70,213);
    
    const EventBlock b1({b1e1, b1e2}),
    b2({b2e1, b2e2}),
    b4({b4e1, b4e2});
    
    EventUID w1 = w1e1;
    EventUID w2 = w1e2;
    
    {
        SCOPED_TRACE("B0");
        cc->setWindow(w1, w2);
        EventBlock gap1({w1,w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B1");
        const EventBlock gap1({w1,w2});
        [self checkEventBlockContainer:{b1} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B2");
        const EventBlock gap1({w1, b2e1}), gap2({b2e2, w2});
        [self checkEventBlockContainer:{b2} expectedGaps:{gap1, gap2} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B3");
        const EventBlock gap1({w1, b2e1}), gap2({b2e2, w2});
        [self checkEventBlockContainer:{e3} expectedGaps:{gap1, gap2} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B4");
        const EventBlock gap1({b4e2, w2});
        [self checkEventBlockContainer:{b4} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B5");
        w1 = w5e1;
        w2 = w5e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({w1, b4e1}), gap2({b4e2, e3}), gap3({e3,w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1, gap2, gap3} container:cc];
    }
    
    {
        SCOPED_TRACE("B6");
        w1 = w6e1;
        w2 = w6e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({b4e2, w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B7");
        w1 = w7e1;
        w2 = w7e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({w1, b4e1}), gap2({b4e2, e3}), gap3({e3, w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1, gap2, gap3} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B8");
        w1 = w8e1;
        w2 = w8e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({w1, w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("B9");
        w1 = w9e1;
        w2 = w9e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({w1, w2});
        [self checkEventBlockContainer:{} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
    {
        SCOPED_TRACE("A10");
        w1 = w10e1;
        w2 = w10e2;
        cc->setWindow(w1, w2);
        const EventBlock gap1({w1, e3});
        [self checkEventBlockContainer:{} expectedGaps:{gap1} container:cc];
        ABORT_ON_FAILURE();
    }
    
}

@end
