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

#import "EventUID.h"
#import <vector>
#import <random>

#define ASSERT_EQ(a, b) XCTAssertEqual(a, b)
#define ASSERT_TRUE(a) XCTAssertTrue(a)
#define ASSERT_FALSE(a) XCTAssertFalse(a)
#define ASSERT_NE(a, b) XCTAssertNotEqual(a, b)
#define ASSERT_LE(a, b) XCTAssertTrue(a <= b)
#define ASSERT_LT(a, b) XCTAssertTrue(a < b)
#define ASSERT_GE(a, b) XCTAssertTrue(a >= b)
#define ASSERT_GT(a, b) XCTAssertTrue(a > b)


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


@interface ZMEventUIDTests : ZMTBaseTest

@end

@implementation ZMEventUIDTests

- (void)sortAndCheckOrder:(std::vector<EventUID>&)events
{
    std::sort(events.begin(), events.end());
    
    EventUID last;
    for(auto e : events) {
        XCTAssertTrue(e >= last);
        XCTAssertTrue(e.sequence >= last.sequence);
        
        if(last.sequence == e.sequence) {
            XCTAssertTrue(e.random >= last.random);
        }
        last = e;
    }
    
}


- (void)testThatItSortsCorrectly_1
{
    
    auto e1 = EventUID(10, 3245);
    ASSERT_EQ(e1.sequence, 10);
    ASSERT_EQ(e1.random, 3245U);
    
    EventUID e2(e1);
    ASSERT_EQ(e2.sequence, 10);
    ASSERT_EQ(e2.random, 3245U);
    ASSERT_EQ(e1, e2);
    
    ASSERT_TRUE(EventUID().empty());
    ASSERT_TRUE(EventUID::UID_NONE.empty());
    ASSERT_FALSE(EventUID(1,1).empty());
    
    ASSERT_EQ(EventUID(1, 132), EventUID(1, 132));
    ASSERT_EQ(EventUID::UID_NONE, EventUID::UID_NONE);
    ASSERT_TRUE(EventUID() == EventUID::UID_NONE);
    
    ASSERT_NE(EventUID::UID_NONE, EventUID(5, 123));
    
    ASSERT_LE(EventUID(10, 4), EventUID(10, 4));
    ASSERT_LE(EventUID(10, 6), EventUID(10, 10));
    ASSERT_LE(EventUID(8, 10), EventUID(10, 0));
    
    ASSERT_LT(EventUID(12, 6), EventUID(12, 10));
    ASSERT_LT(EventUID(123, 0), EventUID(123, 80));
    
    ASSERT_GE(EventUID(213, 321), EventUID(213, 321));
    ASSERT_GE(EventUID(213, 321), EventUID(4, 1234));
    ASSERT_GE(EventUID(1, 43), EventUID(1, 3));
    
    ASSERT_GT(EventUID(213, 321), EventUID(4, 1234));
    ASSERT_GT(EventUID(1, 43), EventUID(1, 3));

}

- (void)testThatItSortsCorrectly_2
{
    
    {
        
        std::vector<EventUID> original = {
            {-1,0},
            {-1,100},
            {1,21312},
            {23,342423},
            {100,0},
            {3442,0},
            {3442,0},
            {3442,231},
            {4533,32},
            {4552,432},
            {4553,1}
        };
        
        std::mt19937_64 generator(21534);

        // shuffle 100 times, check that we always get the expected result
        for(size_t i = 0; i < 100; ++i) {
            std::vector<EventUID> copy(original);
            std::shuffle(copy.begin(), copy.end(), generator);
            [self sortAndCheckOrder:copy];
            XCTAssertEqual(copy, original);
        }
    }
    
    {
        
        std::vector<EventUID> evt;
        fillRandomVector(evt, 1000000, 2341);
        evt.push_back(EventUID(-1,0));
        
        [self sortAndCheckOrder:evt];
        XCTAssertEqual(evt[0], EventUID(-1, 0));
    }
}


@end
