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


@import XCTest;
@import WireTransport;
@import WireTesting;


#import "ZMBackendEnvironment+Testing.h"

@interface ZMBackendEnvironmentTests : ZMTBaseTest

@end

@implementation ZMBackendEnvironmentTests

- (NSString *)backendHostForType:(NSString *)type
{
    return [NSString stringWithFormat:@"backend.%@example.com/some/path", [type isEqualToString:@"Production"] ? @"" : [[type lowercaseString] stringByAppendingString:@"."]];
}

- (NSString *)wsBackendHostForType:(NSString *)type
{
    return [NSString stringWithFormat:@"ws.%@example.com/some/path", [type isEqualToString:@"Production"] ? @"" : [[type lowercaseString] stringByAppendingString:@"."]];
}

- (NSString *)blackListHostForType:(NSString *)type
{
    return [NSString stringWithFormat:@"blacklist.%@example.com/some/path", [type isEqualToString:@"Production"] ? @"" : [[type lowercaseString] stringByAppendingString:@"."]];
}

- (NSString *)frontendHostForType:(NSString *)type
{
    return [NSString stringWithFormat:@"frontend.%@example.com/some/path", [type isEqualToString:@"Production"] ? @"" : [[type lowercaseString] stringByAppendingString:@"."]];
}

- (void)setUp {
    [super setUp];
    
    for (NSNumber *type in @[@(ZMBackendEnvironmentTypeEdge), @(ZMBackendEnvironmentTypeStaging), @(ZMBackendEnvironmentTypeProduction)]) {
        NSString *typeString = [ZMBackendEnvironment environmentTypeAsString:type.integerValue];
        [ZMBackendEnvironment setupEnvironmentOfType:type.integerValue
                                     withBackendHost:[self backendHostForType:typeString]
                                              wsHost:[self wsBackendHostForType:typeString]
                                   blackListEndpoint:[self blackListHostForType:typeString]
                                        frontendHost:[self frontendHostForType:typeString]];
    }
    WaitForAllGroupsToBeEmpty(0.1);
}

- (void)tearDown {
    [super tearDown];
}

- (void)checkURLsForEnvironment:(ZMBackendEnvironment *)env type:(ZMBackendEnvironmentType)type
{
    NSString *typeString = [ZMBackendEnvironment environmentTypeAsString:type];
    NSURL *expectedBackendURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [self backendHostForType:typeString]]];
    XCTAssertEqualObjects([env backendURL], expectedBackendURL, @"It should return expected backend url");

    NSURL *expectedWSBackendURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [self wsBackendHostForType:typeString]]];
    XCTAssertEqualObjects([env backendWSURL], expectedWSBackendURL, @"It should return expected websocket url");

    NSURL *expectedBlacklistURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [self blackListHostForType:typeString]]];
    XCTAssertEqualObjects([env blackListURL], expectedBlacklistURL, @"It should return expected black list url");
    
    NSURL *expectedFrontendURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [self frontendHostForType:typeString]]];
    XCTAssertEqualObjects([env frontendURL], expectedFrontendURL, @"It should return expected frontend url");
}

- (void)testThatItRetunsExpectedURLsForEdge
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"tests"];
    [defaults setObject:[ZMBackendEnvironment environmentTypeAsString:ZMBackendEnvironmentTypeEdge] forKey:ZMBackendEnvironmentTypeKey];
    ZMBackendEnvironment *sut = [[ZMBackendEnvironment alloc] initWithUserDefaults:defaults];
    [self checkURLsForEnvironment:sut type:ZMBackendEnvironmentTypeEdge];
}

- (void)testThatItRetunsExpectedURLsForStaging
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"tests"];
    [defaults setObject:[ZMBackendEnvironment environmentTypeAsString:ZMBackendEnvironmentTypeStaging] forKey:ZMBackendEnvironmentTypeKey];
    ZMBackendEnvironment *sut = [[ZMBackendEnvironment alloc] initWithUserDefaults:defaults];
    [self checkURLsForEnvironment:sut type:ZMBackendEnvironmentTypeStaging];
}

- (void)testThatItRetunsExpectedURLsForProduction
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"tests"];
    [defaults setObject:[ZMBackendEnvironment environmentTypeAsString:ZMBackendEnvironmentTypeProduction] forKey:ZMBackendEnvironmentTypeKey];
    ZMBackendEnvironment *sut = [[ZMBackendEnvironment alloc] initWithUserDefaults:defaults];
    [self checkURLsForEnvironment:sut type:ZMBackendEnvironmentTypeProduction];
}

- (void)testThatItFallsBackToProductionEnvironment
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"tests"];
    [defaults setObject:@"Default" forKey:ZMBackendEnvironmentTypeKey];
    ZMBackendEnvironment *sut = [[ZMBackendEnvironment alloc] initWithUserDefaults:defaults];
    [self checkURLsForEnvironment:sut type:ZMBackendEnvironmentTypeProduction];
}

- (void)testThatItReturnsTheProductionEnvironment
{
    [self checkURLsForEnvironment:[ZMBackendEnvironment environmentWithType:ZMBackendEnvironmentTypeProduction] type:ZMBackendEnvironmentTypeProduction];
}

- (void)testThatItReturnsTheStagingEnvironment
{
    [self checkURLsForEnvironment:[ZMBackendEnvironment environmentWithType:ZMBackendEnvironmentTypeStaging] type:ZMBackendEnvironmentTypeStaging];
}

- (void)testThatItReturnsTheEdgeEnvironment
{
    [self checkURLsForEnvironment:[ZMBackendEnvironment environmentWithType:ZMBackendEnvironmentTypeEdge] type:ZMBackendEnvironmentTypeEdge];
}

@end
