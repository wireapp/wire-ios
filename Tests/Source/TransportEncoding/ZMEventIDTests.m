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


@import ZMTransport;
@import ZMTesting;

@interface ZMEventIDTests : XCTestCase

@property (nonatomic) NSArray *identifierStrings;

@end




@implementation ZMEventIDTests

- (void)setUp;
{
    [super setUp];
    self.identifierStrings = @[
                               @"1.80011231430888ef",
                               @"10.80011231430865e9",
                               @"11.80011231430867e2",
                               @"12.80011231430867e3",
                               @"13.8001123143088388",
                               @"14.800112314308857f",
                               @"15.8001123143088580",
                               @"16.8001123143088581",
                               @"17.8001123143088587",
                               @"18.80011231430885a4",
                               @"19.80011231430885ab",
                               @"1a.8001123143088623",
                               @"1b.8001123143088625",
                               @"1c.8001123143088678",
                               @"1d.80011231430886af",
                               @"1e.80011231430886d8",
                               @"1f.80011231430886ec",
                               @"2.80011231430888f0",
                               @"20.80011231430886ee",
                               @"21.80011231430886ef",
                               @"22.80011231430886f0",
                               @"23.80011231430886f1",
                               @"24.80011231430886f2",
                               @"25.80011231430886f3",
                               @"26.80011231430886f5",
                               @"27.80011231430886f6",
                               @"28.80011231430886f7",
                               @"29.80011231430886f8",
                               @"2a.8001123143088718",
                               @"2b.8001123143088719",
                               @"2c.800112314308871a",
                               @"2d.800112314308871c",
                               @"2e.800112314308871d",
                               @"2f.800112314308871e",
                               @"3.80011231430888f8",
                               @"30.800112314308871f",
                               @"31.8001123143088720",
                               @"32.8001123143088721",
                               @"33.8001123143088722",
                               @"34.8001123143088723",
                               @"35.8001123143088724",
                               @"36.8001123143088725",
                               @"37.8001123143088726",
                               @"38.8001123143088727",
                               @"39.8001123143088728",
                               @"3a.8001123143088729",
                               @"3b.800112314308872a",
                               @"3c.800112314308872b",
                               @"3d.800112314308872c",
                               @"3e.800112314308872d",
                               @"3f.800112314308872e",
                               @"4.80011231430888f9",
                               @"40.800112314308872f",
                               @"41.8001123143088730",
                               @"42.8001123143088731",
                               @"43.8001123143088732",
                               @"44.8001123143088733",
                               @"45.8001123143088734",
                               @"46.8001123143088735",
                               @"47.8001123143088736",
                               @"48.8001123143088737",
                               @"49.8001123143088738",
                               @"4a.8001123143088739",
                               @"4b.800112314308873a",
                               @"4c.800112314308873b",
                               @"4d.800112314308873c",
                               @"4e.800112314308873d",
                               @"4f.800112314308873e",
                               @"5.80011231430888fa",
                               @"50.800112314308873f",
                               @"51.8001123143088742",
                               @"52.800112314308877e",
                               @"53.800112314308877f",
                               @"54.8001123143088780",
                               @"55.8001123143088781",
                               @"56.8001123143088782",
                               @"57.8001123143088783",
                               @"58.8001123143088784",
                               @"58.8001123143088785",
                               @"59.8001123143088786",
                               @"5a.8001123143088787",
                               @"5b.8001123143088788",
                               @"5c.8001123143088789",
                               @"5d.800112314308878a",
                               @"5e.800112314308878b",
                               @"5f.800112314308878c",
                               @"6.80011231430888fb",
                               @"60.800112314308878d",
                               @"61.800112314308878e",
                               @"62.800112314308878f",
                               @"63.8001123143088790",
                               @"7.80011231430888fc",
                               @"8.80011231430888fd",
                               @"9.80011231430888fe",
                               @"a.8001123143088901",
                               @"b.8001123143088902",
                               @"c.800112314308890b",
                               @"d.800112314308890c",
                               @"e.8001123143083ab4",
                               @"f.80011231430865e8",
                               @"1.8001123143087266",
                               @"10.8001123143087284",
                               @"11.8001123143087287",
                               @"12.8001123143087288",
                               @"13.8001123143087289",
                               @"14.800112314308728a",
                               @"15.800112314308728b",
                               @"16.8001123143087293",
                               @"17.8001123143087295",
                               @"18.8001123143087297",
                               @"19.8001123143087299",
                               @"1a.80011231430872a1",
                               @"1b.80011231430872a2",
                               @"1c.80011231430872a3",
                               @"1d.80011231430872bb",
                               @"1e.80011231430872bc",
                               @"1f.80011231430872bd",
                               @"2.8001123143087267",
                               @"20.80011231430872be",
                               @"21.80011231430872c0",
                               @"22.8001123143087473",
                               @"23.8001123143087475",
                               @"24.8001123143087513",
                               @"25.8001123143087514",
                               @"26.8001123143087521",
                               @"27.8001123143087522",
                               @"28.800112314308758c",
                               @"29.800112314308758e",
                               @"2a.8001123143087593",
                               @"2b.8001123143087596",
                               @"2c.800112314308759c",
                               @"2d.800112314308759d",
                               @"2e.800112314308759e",
                               @"2f.80011231430875ce",
                               @"3.8001123143087269",
                               @"30.80011231430875d0",
                               @"31.80011231430875d8",
                               @"32.80011231430875da",
                               @"33.80011231430875dc",
                               @"34.80011231430875dd",
                               @"35.80011231430875df",
                               @"36.80011231430875e0",
                               @"37.80011231430875e1",
                               @"38.80011231430875e2",
                               @"39.8001123143087642",
                               @"3a.8001123143087643",
                               @"3b.800112314308764e",
                               @"3c.8001123143087a8c",
                               @"3d.8001123143087a8d",
                               @"3e.8001123143087a8e",
                               @"3f.8001123143087a8f",
                               @"4.800112314308726a",
                               @"40.8001123143087a93",
                               @"41.8001123143087a9c",
                               @"42.8001123143087a9d",
                               @"43.8001123143087aa4",
                               @"44.8001123143087aa6",
                               @"45.8001123143087aa8",
                               @"46.8001123143087aae",
                               @"47.8001123143087ab2",
                               @"48.8001123143087ab3",
                               @"49.8001123143087ac1",
                               @"4a.8001123143087ac3",
                               @"4b.8001123143087afd",
                               @"4c.8001123143087aff",
                               @"4d.8001123143087b03",
                               @"4e.8001123143087b05",
                               @"4f.8001123143087b24",
                               @"5.800112314308726c",
                               @"50.8001123143087b36",
                               @"51.8001123143087b37",
                               @"52.8001123143087b39",
                               @"53.8001123143087b40",
                               @"54.8001123143087b41",
                               @"55.8001123143087b85",
                               @"56.8001123143087b87",
                               @"57.8001123143087bae",
                               @"58.8001123143087be2",
                               @"59.8001123143087be8",
                               @"5a.8001123143087c41",
                               @"5b.8001123143087c4a",
                               @"5c.8001123143087c4b",
                               @"5d.8001123143087c4d",
                               @"5e.8001123143087c4f",
                               @"5f.8001123143087c50",
                               @"6.800112314308726e",
                               @"60.8001123143087c52",
                               @"61.8001123143087c58",
                               @"62.8001123143087c59",
                               @"63.8001123143087c5a",
                               @"64.8001123143087c61",
                               @"7.8001123143087272",
                               @"8.8001123143087276",
                               @"9.8001123143087278",
                               @"a.8001123143087279",
                               @"b.800112314308727a",
                               @"c.800112314308727d",
                               @"d.800112314308727e",
                               @"e.8001123143087280",
                               @"f.8001123143087282",
                               ];
}

- (void)testThatValidStringsCreateValidEventIDs
{
    for (NSString *string in self.identifierStrings) {
        ZMEventID *e0 = [ZMEventID eventIDWithString:string];
        XCTAssertNotNil(e0, @"Failed to parse \"%@\"", string);
    }
}

- (void)testThatInvalidStringsReturnNilOnCreation
{
    NSArray *invalidStrings =
    @[
      @"",
      @"f.80.f",
      @"f.f.80",
      @"f..80",
      @"wf.80",
      @"f.80w",
      // @" f.80", // Apparently having a space character in front of a hex number is ok for parsing.
      @"f 80 ",
      @"f.80 ",
      @"e.80011231430872808001123143087280",
      @"80011231430872808001123143087280.e",
      ];
    for (NSString *string in invalidStrings) {
        XCTAssertNil([ZMEventID eventIDWithString:string], @"Parsing \"%@\" should return nil", string);
    }
}

- (void)testThatEventIDsWithEqualStringsReturnIsEqualYES
{
    for (NSString *string in self.identifierStrings) {
        ZMEventID *e0 = [ZMEventID eventIDWithString:string];
        ZMEventID *e1 = [ZMEventID eventIDWithString:string];
        XCTAssertEqualObjects(e0, e1, @"Creating \"%@\" twice doesn't compare equal.", string);
    }
}

- (void)testThatEventIDsWithDifferingStringsReturnIsEqualNO
{
    for (NSString *string0 in self.identifierStrings) {
        ZMEventID *e0 = [ZMEventID eventIDWithString:string0];
        for (NSString *string1 in self.identifierStrings) {
            ZMEventID *e1 = [ZMEventID eventIDWithString:string1];
            if (! [string0 isEqualToString:string1]) {
                XCTAssertNotEqualObjects(e0, e1, @"ID \"%@\" should not be equal to \"%@\"", string0, string1);
            }
        }
    }
}

- (void)testThatEventIDsWithEqualStringsCompareAsSame
{
    for (NSString *string in self.identifierStrings) {
        ZMEventID *e0 = [ZMEventID eventIDWithString:string];
        ZMEventID *e1 = [ZMEventID eventIDWithString:string];
        XCTAssertEqual([e0 compare:e1], NSOrderedSame, @"Creating \"%@\" twice doesn't compare equal.", string);
    }
}

- (void)testThatEventIDsWithDifferingStringsCompareAsDifferent
{
    for (NSString *string0 in self.identifierStrings) {
        ZMEventID *e0 = [ZMEventID eventIDWithString:string0];
        for (NSString *string1 in self.identifierStrings) {
            ZMEventID *e1 = [ZMEventID eventIDWithString:string1];
            if (! [string0 isEqualToString:string1]) {
                XCTAssertNotEqual([e0 compare:e1], NSOrderedSame, @"ID \"%@\" should not be equal to \"%@\"", string0, string1);
            }
        }
    }
}

- (void)testThatEventIDsAreOrdered
{
    NSArray *ascendingPairs =
    @[
      @[@"62.8001123143087c59", @"62.8001123143087c5a",],
      @[@"62.8001123143087c59", @"63.8001123143087c59",],
      ];
    
    for (NSArray *pair in ascendingPairs) {
        NSString *string0 = pair[0];
        NSString *string1 = pair[1];
        ZMEventID *e0 = [ZMEventID eventIDWithString:string0];
        ZMEventID *e1 = [ZMEventID eventIDWithString:string1];
        XCTAssertEqual([e0 compare:e1], NSOrderedAscending, @"%@ < %@", string0, string1);
        XCTAssertEqual([e1 compare:e0], NSOrderedDescending, @"%@ > %@", string1, string0);
    }
}

- (void)testThatItReturnsTheEarlierEventID
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithMajor:100 minor:1000000];
    ZMEventID *event2 = [ZMEventID eventIDWithMajor:1000 minor:23124];
    ZMEventID *event3 = [ZMEventID eventIDWithMajor:10 minor:123124];
    
    // then
    XCTAssertEqualObjects([ZMEventID earliestOfEventID:event1 and:event2], event1);
    XCTAssertEqualObjects([ZMEventID earliestOfEventID:event1 and:event3], event3);
}

- (void)testThatItReturnsTheLatestEventID
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithMajor:100 minor:1000000];
    ZMEventID *event2 = [ZMEventID eventIDWithMajor:1000 minor:23124];
    ZMEventID *event3 = [ZMEventID eventIDWithMajor:10 minor:123124];
    
    // then
    XCTAssertEqualObjects([ZMEventID latestOfEventID:event1 and:event2], event2);
    XCTAssertEqualObjects([ZMEventID latestOfEventID:event1 and:event3], event1);
}

- (void)testThatCompareDoesNotCrashWithNullEventID
{
    // given
    ZMEventID *event1 = [ZMEventID eventIDWithMajor:10 minor:2312314];
    ZMEventID *event2 = nil;
    
    // when
    NSComparisonResult result = [event1 compare:event2];
    
    // then
    XCTAssertEqual(result, NSOrderedDescending);
}

@end
