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
@import WireUtilities;
@import OCMock;


static NSString *const BundleIDProduction = @"com.wearezeta.zclient.ios";
static NSString *const BundleIDAlpha = @"com.wearezeta.zclient-alpha";
static NSString *const BundleIDDevelopment = @"com.wearezeta.zclient.ios-development";
static NSString *const BundleIDInternalBuild = @"com.wearezeta.zclient.ios-internal";

static NSString *const CertificateNameProduction = @"com.wire";
static NSString *const CertificateNameAlpha = @"com.wire.ent";
static NSString *const CertificateNameDevelopment = @"com.wire.dev.ent";
static NSString *const CertificateNameInternal = @"com.wire.int.ent";

static NSString *const TransportTypeAPNS = @"APNS";
static NSString *const TransportTypeAPNS_VoIP = @"APNS_VOIP";
static NSString *const TransportTypeAPNS_Sandbox = @"APNS_SANDBOX";
static NSString *const TransportTypeAPNS_VoIP_Sandbox = @"APNS_VOIP_SANDBOX";

static NSString *const FallbackAPNS = @"APNS";
static NSString *const FallbackAPNS_Sandbox = @"APNS_SANDBOX";

@interface ZMAPNSEnvironmentTests : XCTestCase

@end

@implementation ZMAPNSEnvironmentTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [ZMAPNSEnvironment setupForProductionWithCertificateName:CertificateNameProduction];
    [ZMAPNSEnvironment setupForEnterpriseWithBundleId:BundleIDAlpha withCertificateName:CertificateNameAlpha];
    [ZMAPNSEnvironment setupForEnterpriseWithBundleId:BundleIDDevelopment withCertificateName:CertificateNameDevelopment];
    [ZMAPNSEnvironment setupForEnterpriseWithBundleId:BundleIDInternalBuild withCertificateName:CertificateNameInternal];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItReturnsExpectedTransportTypes
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *transportType = [sut transportTypeForTokenType:ZMAPNSTypeNormal];
    XCTAssertEqualObjects(transportType, TransportTypeAPNS);
    NSString *voipTansportType = [sut transportTypeForTokenType:ZMAPNSTypeVoIP];
    XCTAssertEqualObjects(voipTansportType, TransportTypeAPNS_VoIP);
}

- (void)testThatItReturnsExpectedTransportTypesSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *transportType = [sut transportTypeForTokenType:ZMAPNSTypeNormal];
    XCTAssertEqualObjects(transportType, TransportTypeAPNS_Sandbox);
    NSString *voipTansportType = [sut transportTypeForTokenType:ZMAPNSTypeVoIP];
    XCTAssertEqualObjects(voipTansportType, TransportTypeAPNS_VoIP_Sandbox);
}

- (void)testThatItReturnsExpectedFallback
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *fallback = [sut fallbackForTransportType:ZMAPNSTypeVoIP];
    XCTAssertEqualObjects(fallback, FallbackAPNS);
    
    fallback = [sut fallbackForTransportType:ZMAPNSTypeNormal];
    XCTAssertNil(fallback);
}

- (void)testThatItReturnsExpectedFallbackSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *fallback = [sut fallbackForTransportType:ZMAPNSTypeVoIP];
    XCTAssertEqualObjects(fallback, FallbackAPNS_Sandbox);
    
    fallback = [sut fallbackForTransportType:ZMAPNSTypeNormal];
    XCTAssertNil(fallback);
}

- (void)testThatItReturnsExpectedPushIdentifierForProduction
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameProduction;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForProductionSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamAppStore)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameProduction;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForAlpha
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDAlpha];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameAlpha;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForAlphaSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDAlpha];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameAlpha;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForInternal
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDInternalBuild];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameInternal;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForInternalSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDInternalBuild];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameInternal;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForDevelopment
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentProduction)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDDevelopment];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameDevelopment;
    XCTAssertEqualObjects(token, expectedToken);
}

- (void)testThatItReturnsExpectedPushIdentifierForDevelopmentSandbox
{
    id parser = [OCMockObject mockForClass:[ZMMobileProvisionParser class]];
    [[[parser stub] andReturnValue:@(ZMAPSEnvironmentSandbox)] APSEnvironment];
    [[[parser stub] andReturnValue:@(ZMProvisionTeamEnterprise)] team];
    
    ZMAPNSEnvironment *sut = [[ZMAPNSEnvironment alloc] initWithParser:parser bundleId:BundleIDDevelopment];
    
    NSString *token = [sut appIdentifier];
    NSString *expectedToken = CertificateNameDevelopment;
    XCTAssertEqualObjects(token, expectedToken);
}

@end
