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


@import WireTesting;
@import WireUtilities;



@interface ZMDeploymentEnvironmentTests : ZMTBaseTest

@property (nonatomic) id mobileProvisionParser;
@property (nonatomic) id mainBundle;

@end



@implementation ZMDeploymentEnvironmentTests

- (void)setUp;
{
    [super setUp];
    self.mobileProvisionParser = [OCMockObject niceMockForClass:ZMMobileProvisionParser.class];
    ZMDeploymentEnvironmentInternalMobileProvisionParserOverride = self.mobileProvisionParser;
}

- (void)tearDown;
{
    ZMDeploymentEnvironmentInternalMobileProvisionParserOverride = nil;
    [super tearDown];
}

- (void)testThatItDetectsAppStoreEnvironment
{
    // given
    [[[self.mobileProvisionParser stub] andReturnValue:OCMOCK_VALUE(ZMProvisionTeamAppStore)] team];
    [[[self.mobileProvisionParser stub] andReturnValue:OCMOCK_VALUE(ZMAPSEnvironmentProduction)] APSEnvironment];
    
    // when
    ZMDeploymentEnvironmentType t = [[ZMDeploymentEnvironment alloc] init].environmentType;
    
    // then
    XCTAssertEqual(t, ZMDeploymentEnvironmentTypeAppStore);
}

- (void)testThatItDetectsInternalEnvironment
{
    // given
    [[[self.mobileProvisionParser stub] andReturnValue:OCMOCK_VALUE(ZMProvisionTeamEnterprise)] team];
    [[[self.mobileProvisionParser stub] andReturnValue:OCMOCK_VALUE(ZMAPSEnvironmentProduction)] APSEnvironment];
    
    // when
    ZMDeploymentEnvironmentType t = [[ZMDeploymentEnvironment alloc] init].environmentType;
    
    // then
    XCTAssertEqual(t, ZMDeploymentEnvironmentTypeInternal);
}

- (void)testThatItReturnsAppStoreEnvironmentIfThereIsNoProvisioningProfile
{
    // given
    ZMDeploymentEnvironmentInternalMobileProvisionParserOverride = nil;

    // when
    ZMDeploymentEnvironmentType t = [[ZMDeploymentEnvironment alloc] init].environmentType;
    
    // then
    XCTAssertEqual(t, ZMDeploymentEnvironmentTypeAppStore);
}

@end
