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


#import <XCTest/XCTest.h>
#import <ocmock/ocmock.h>
#import "zmessaging.h"
#import "ZMUserSession+Internal.h"
#import "IntegrationTestBase.h"
#import "ZMAddressBook.h"
#import "ZMAddressBookContact.h"


@interface MockSearchResultObserver : NSObject <ZMSearchResultObserver>
@property (nonatomic, strong) void (^completionBlock)(ZMSearchResult *, ZMSearchToken);
- (instancetype)initWithBlock:(void (^)(ZMSearchResult *, ZMSearchToken))completionBlock;
@end

@implementation MockSearchResultObserver

- (instancetype)initWithBlock:(void (^)(ZMSearchResult *result, ZMSearchToken token))completionBlock;
{
    if (!self) return nil;
    _completionBlock = completionBlock;
    return self;
}

- (void)didReceiveSearchResult:(ZMSearchResult *)result forToken:(ZMSearchToken)searchToken;
{
    self.completionBlock(result, searchToken);
}

@end


@interface InvitationTests : IntegrationTestBase
{
    id _mockAddressBook;
}
@property (nonatomic, strong) ZMSearchDirectory *searchDirectory;
@property (nonatomic, strong) NSArray *addressBookContacts;

@end

@implementation InvitationTests

- (void)setUp {
    [super setUp];
    [self updateDisplayNameGeneratorWithUsers:self.allUsers];
    self.searchDirectory = [[ZMSearchDirectory alloc] initWithUserSession:self.userSession];
}

- (void)tearDown {
    [_mockAddressBook stopMocking];
    _mockAddressBook = nil;
    [self.searchDirectory tearDown];
    self.searchDirectory = nil;
    self.addressBookContacts = nil;
    [super tearDown];
}

- (NSArray<ZMAddressBookContact *> *)addressBookWithContainingEmails:(BOOL)shouldSetEmails phoneNumbers:(BOOL)shouldSetPhones;
{
    NSArray *firstNames = @[@"Jean", @"Jaques", @"Jules", @"Jeane", @"Julie"];
    NSArray *lastNames = @[@"Dupont", @"Dupuit", @"Deschamps", @"Desbois", @"Dujardin"];
    NSArray *mails = @[@"Jean@example.com", @"Jaques@example.com", @"Jules@example.com", @"Jeane@wire.com", @"Julie@wire.com"];
    NSArray *phoneNumbers = @[@"191295921341", @"123012345349", @"028340980034", @"298403123498", @"109878946541"];

    NSMutableArray<ZMAddressBookContact *> *contacts = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < [firstNames count]; ++i) {
            
        ZMAddressBookContact *contact = [[ZMAddressBookContact alloc] init];
        contact.firstName = firstNames[i];
        contact.lastName = lastNames[i];
        if (shouldSetPhones) {contact.phoneNumbers = @[phoneNumbers[i]]; }
        if (shouldSetEmails) {contact.emailAddresses = @[mails[i]]; }
        
        [contacts addObject:contact];
    }
    return [contacts copy];
}

- (ZMAddressBookContact *)addressBookContactWithUser:(MockUser *)mockUser;
{
    ZMAddressBookContact *contact = [[ZMAddressBookContact alloc] init];
    contact.firstName = mockUser.name;
    contact.emailAddresses = @[mockUser.email];
    contact.phoneNumbers = @[mockUser.phone];
    return contact;
}

- (void)setupAddressBook;
{
    self.addressBookContacts = [self addressBookWithContainingEmails:YES phoneNumbers:YES];
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:self.addressBookContacts];
}

- (void)setupAddressBookStubsWithAuthorizationAccess:(BOOL)authorized contacts:(NSArray *)contacts;
{
    _mockAddressBook = [OCMockObject mockForClass:[ZMAddressBook class]];
    [[[[_mockAddressBook stub] classMethod] andReturnValue:@(authorized)] userHasAuthorizedAccess];
    [[[_mockAddressBook stub] andReturn:contacts] contacts];
    [[[[_mockAddressBook stub] classMethod] andReturn:_mockAddressBook] addressBook] ;
}

- (void)testThatWeGetACorrectPersonalInvitationUrl;
{
        // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
        
        // then
    XCTAssertNotNil([self.userSession checkForPersonalInvitationURL]);
        
}
    
- (void)testThatFetchingUsersWithAddressBookWorksAtAll;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:[self addressBookWithContainingEmails:NO phoneNumbers:YES]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Observer called"];
    
    ZMSearchToken searchToken;
    MockSearchResultObserver *observer = [[MockSearchResultObserver alloc] initWithBlock:^(ZMSearchResult *result __unused, ZMSearchToken token __unused) {
        [expectation fulfill];
    }];
    
    ZMSearchRequest *request = [ZMSearchRequest new];
    request.query = @"";
    request.includeContacts = YES;
    
    [self.searchDirectory addSearchResultObserver:observer];
    
    //when
    searchToken = [self.searchDirectory performRequest:[request copy]];
    
    //then
    XCTAssertNotNil(searchToken);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    [self.searchDirectory removeSearchResultObserver:observer];
}

- (void)testThatWeAreFetchingUsersContactAndAddressBook;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.addressBookContacts =[self addressBookWithContainingEmails:NO phoneNumbers:YES];
    
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:self.addressBookContacts];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Observer called"];
    
    ZMSearchToken searchToken;
    MockSearchResultObserver *observer = [[MockSearchResultObserver alloc] initWithBlock:^(ZMSearchResult *result __unused, ZMSearchToken token __unused) {
        
        XCTAssertEqual(result.usersInContacts.count, self.connectedUsers.count + self.addressBookContacts.count);
        [expectation fulfill];
    }];
    
    ZMSearchRequest *request = [ZMSearchRequest new];
    request.query = @"";
    request.includeContacts = YES;
    request.includeAddressBookContacts = YES;
    [self.searchDirectory addSearchResultObserver:observer];
    
    //when
    searchToken = [self.searchDirectory performRequest:[request copy]];
    
    //then
    XCTAssertNotNil(searchToken);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    [self.searchDirectory removeSearchResultObserver:observer];
}

- (void)testThatFetchingAddressBookContainingRecordWithoutPermissionDoesntFetchAddressBookContact;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    _mockAddressBook = [OCMockObject mockForClass:[ZMAddressBook class]];
    
    [[[_mockAddressBook expect] classMethod] userHasAuthorizedAccess];
    [[[[_mockAddressBook stub] classMethod] andReturnValue:@(NO)] userHasAuthorizedAccess];
    [[[[_mockAddressBook stub] classMethod] andReturn:_mockAddressBook] addressBook] ;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Observer called"];
    
    ZMSearchToken searchToken;
    MockSearchResultObserver *observer = [[MockSearchResultObserver alloc] initWithBlock:^(ZMSearchResult *result __unused, ZMSearchToken token __unused) {
        
        XCTAssertEqual(self.addressBookContacts.count, 0lu);
        XCTAssertEqual(result.usersInContacts.count, self.connectedUsers.count);
        [expectation fulfill];
    }];
    
    ZMSearchRequest *request = [ZMSearchRequest new];
    request.query = @"";
    request.includeContacts = YES;
    request.includeAddressBookContacts = YES;
    
    [self.searchDirectory addSearchResultObserver:observer];
    
    //when
    searchToken = [self.searchDirectory performRequest:[request copy]];
    
    //then
    XCTAssertNotNil(searchToken);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    [_mockAddressBook verify];
    
    [self.searchDirectory removeSearchResultObserver:observer];
}

- (void)testThatWeCanAcceptInvitationAndLoginAfterPreviousCookieWasStillPresent
{
    // given
    [self.mockTransportSession logoutSelfUser];
    [self setupAddressBook];
    
    ZMAddressBookContact *invitee = self.addressBookContacts[0];
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session insertInvitationForSelfUser:self.selfUser inviteeName:invitee.name mail:invitee.emailAddresses[0]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMCompleteRegistrationUser *registrationUser = [ZMCompleteRegistrationUser registrationUserWithEmail:invitee.emailAddresses[0] password:@"test123456" invitationCode:self.mockTransportSession.invitationCode];
    registrationUser.name = invitee.name;
    registrationUser.accentColorValue = ZMAccentColorSoftPink;
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:registrationUser.emailAddress];
    }];
    
    // when we still have a cookie in the cookie store
    [[self.mockTransportSession cookieStorage] setAuthenticationCookieData:[@"12345" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self recreateUserSessionAndWipeCache:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // and we try to register from the invitation
    [self.userSession registerSelfUser:registrationUser];
    
    WaitForAllGroupsToBeEmpty(0.5);

    // then it should have been deleted
    XCTAssertEqualObjects([ZMUser selfUserInContext:self.uiMOC].emailAddress, invitee.emailAddresses[0]);
}


- (void)testThatFetchingContactDoesntDuplicateWireAndAddressBookContact;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSMutableArray *addressBookContacts = [[self addressBookWithContainingEmails:NO phoneNumbers:YES] mutableCopy];
    [addressBookContacts addObject:[self addressBookContactWithUser:self.user1]];
    self.addressBookContacts = [addressBookContacts copy];
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:self.addressBookContacts];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Observer called"];
    ZMSearchToken searchToken;
    MockSearchResultObserver *observer = [[MockSearchResultObserver alloc] initWithBlock:^(ZMSearchResult *result __unused, ZMSearchToken token __unused) {
        
        XCTAssertEqual(result.usersInContacts.count, self.connectedUsers.count + self.addressBookContacts.count - 1lu);
        [expectation fulfill];
    }];
    
    ZMSearchRequest *request = [ZMSearchRequest new];
    request.query = @"";
    request.includeContacts = YES;
    request.includeAddressBookContacts = YES;
    
    [self.searchDirectory addSearchResultObserver:observer];
    
    //when
    searchToken = [self.searchDirectory performRequest:[request copy]];
    
    //then
    XCTAssertNotNil(searchToken);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    [self.searchDirectory removeSearchResultObserver:observer];
}

- (void)testThatInvitingTriggersARequest;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self setupAddressBook];
    ZMAddressBookContact *invitee = [self.addressBookContacts firstObject];
    ZMPersonName *selfUserPersonName = [ZMPersonName personWithName:self.selfUser.name];
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Invitation request"];
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request ) {
        XCTAssertEqual(request.method, ZMMethodPOST);
        XCTAssertEqualObjects(request.path, @"/invitations");
        
        XCTAssertEqualObjects(selfUserPersonName.givenName, [[request.payload asDictionary] stringForKey:@"inviter_name"]);
        XCTAssertEqualObjects(invitee.name, [[request.payload asDictionary] stringForKey:@"invitee_name"]);
        XCTAssertNotNil([[request.payload asDictionary] objectForKey:@"message"]);
        [expectation fulfill];
        return ZMCustomResponseGeneratorReturnResponseNotCompleted;
    };
    
    //when
    [invitee inviteWithEmail:invitee.emailAddresses[0] toGroupConversation:nil userSession:self.userSession];
   
    //then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatInvitingAUserWithEmailCreatesAnInvitationInBackend;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self setupAddressBook];
    ZMAddressBookContact *invitee = [self.addressBookContacts firstObject];
    
    //when
    [invitee inviteWithEmail:invitee.emailAddresses[0] toGroupConversation:nil userSession:self.userSession];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"inviter == %@ AND inviteeEmail == %@", self.selfUser, invitee.emailAddresses[0]];
    NSFetchRequest *invitationFetchRequest = [MockPersonalInvitation sortedFetchRequestWithPredicate:fetchPredicate];
    NSArray *invitations = [self.mockTransportSession.managedObjectContext executeFetchRequest:invitationFetchRequest error:nil];
    XCTAssertEqual(invitations.count, 1lu);
}

- (void)testThatInvitingAUserWithPhoneCreatesAnInvitationInBackend;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self setupAddressBook];
    ZMAddressBookContact *invitee = [self.addressBookContacts firstObject];
    
    //when
    [invitee inviteWithPhoneNumber:invitee.phoneNumbers[0] toGroupConversation:nil userSession:self.userSession];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"inviter == %@ AND inviteePhone == %@", self.selfUser, invitee.phoneNumbers[0]];
    NSFetchRequest *invitationFetchRequest = [MockPersonalInvitation sortedFetchRequestWithPredicate:fetchPredicate];
    NSArray *invitations = [self.mockTransportSession.managedObjectContext executeFetchRequest:invitationFetchRequest error:nil];
    XCTAssertEqual(invitations.count, 1lu);
}


- (void)testThatInvitingAWireUserReturnsACreatedConnectionToThatUser;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMAddressBookContact *invitee = [self addressBookContactWithUser:self.user5];
    self.addressBookContacts = [self addressBookWithContainingEmails:YES phoneNumbers:YES];
    self.addressBookContacts = [self.addressBookContacts arrayByAddingObject:invitee];
    
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:self.addressBookContacts];
    
    //when
    [invitee inviteWithEmail:invitee.emailAddresses[0] toGroupConversation:nil userSession:self.userSession];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"inviter == %@ AND inviteeEmail == %@", self.selfUser, invitee.emailAddresses[0]];
    NSFetchRequest *invitationFetchRequest = [MockPersonalInvitation sortedFetchRequestWithPredicate:fetchPredicate];
    NSArray *invitations = [self.mockTransportSession.managedObjectContext executeFetchRequest:invitationFetchRequest error:nil];
    XCTAssertEqual(invitations.count, 0lu);
    
    NSPredicate *connectionFetchPredicate = [NSPredicate predicateWithFormat:@"from == %@ AND to == %@", self.selfUser, self.user5];
    NSFetchRequest *connectionFetchRequest = [MockConnection sortedFetchRequest];
    connectionFetchRequest.predicate = connectionFetchPredicate;
    NSArray *connections = [self.mockTransportSession.managedObjectContext executeFetchRequest:connectionFetchRequest error:nil];
    XCTAssertEqual(connections.count, 1lu);
}

- (void)testThatInvitingAWireUserReturnsTheAlreadyCreatedConnectionToThatUser;
{
    //given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block MockConnection *connection;
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        connection = [session createConnectionRequestFromUser:self.selfUser toUser:self.user3 message:@"You won the Gemini Croquet contest. Let's go to Floston Paradise!"];
    }];
    
    ZMAddressBookContact *invitee = [self addressBookContactWithUser:self.user3];
    self.addressBookContacts = [self addressBookWithContainingEmails:YES phoneNumbers:YES];
    self.addressBookContacts = [self.addressBookContacts arrayByAddingObject:invitee];
    [self setupAddressBookStubsWithAuthorizationAccess:YES contacts:self.addressBookContacts];
    
    //when
    [invitee inviteWithEmail:invitee.emailAddresses[0] toGroupConversation:nil userSession:self.userSession];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"inviter == %@ AND inviteeEmail == %@", self.selfUser, invitee.emailAddresses[0]];
    NSFetchRequest *invitationFetchRequest = [MockPersonalInvitation sortedFetchRequestWithPredicate:fetchPredicate];
    NSArray *invitations = [self.mockTransportSession.managedObjectContext executeFetchRequest:invitationFetchRequest error:nil];
    XCTAssertEqual(invitations.count, 0lu);
    
    NSPredicate *connectionFetchPredicate = [NSPredicate predicateWithFormat:@"from == %@ AND to == %@", self.selfUser, self.user3];
    NSFetchRequest *connectionFetchRequest = [MockConnection sortedFetchRequest];
    connectionFetchRequest.predicate = connectionFetchPredicate;
    NSArray *connections = [self.mockTransportSession.managedObjectContext executeFetchRequest:connectionFetchRequest error:nil];
    XCTAssertEqual(connections.count, 1lu);
    XCTAssertEqualObjects([connections firstObject], connection);
}


- (void)testThatRegisteringInviteeWithWrongInvitationCodeFails;
{
    // given
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);

    [self setupAddressBook];
    ZMAddressBookContact *invitee = [self.addressBookContacts firstObject];
    [invitee inviteWithEmail:[invitee.emailAddresses firstObject] toGroupConversation:nil userSession:self.userSession];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self recreateUserSessionAndWipeCache:YES];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMCompleteRegistrationUser *registrationUser = [ZMCompleteRegistrationUser registrationUserWithEmail:invitee.emailAddresses[0] password:@"test123456" invitationCode:self.mockTransportSession.invalidInvitationCode];
    registrationUser.name = invitee.name;
    registrationUser.accentColorValue = ZMAccentColorSoftPink;
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:registrationUser.emailAddress];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    id mockRegistrationObserver = [OCMockObject mockForProtocol:@protocol(ZMRegistrationObserver)];
    id regToken = [self.userSession addRegistrationObserver:mockRegistrationObserver];
    
    // expectation
    [[mockRegistrationObserver expect] registrationDidFail:[OCMArg checkWithBlock:^BOOL(NSError *error) {
        XCTAssertEqual(error.code, (long)ZMUserSessionInvalidInvitationCode);
        return YES;
    }]];
    
    // when
    [self.userSession registerSelfUser:registrationUser];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [mockRegistrationObserver verify];
    
    [self.userSession removeRegistrationObserverForToken:regToken];
}


- (void)testThatRegisteringInviteeReceiveConnectionAndConversationWithInviter;
{
    // given
    [self.mockTransportSession logoutSelfUser];
    
    [self setupAddressBook];
    ZMAddressBookContact *invitee = self.addressBookContacts[0];
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session insertInvitationForSelfUser:self.selfUser inviteeName:invitee.name mail:invitee.emailAddresses[0]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    
    ZMCompleteRegistrationUser *registrationUser = [ZMCompleteRegistrationUser registrationUserWithEmail:invitee.emailAddresses[0] password:@"test123456" invitationCode:self.mockTransportSession.invitationCode];
    registrationUser.name = invitee.name;
    registrationUser.accentColorValue = ZMAccentColorSoftPink;
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:registrationUser.emailAddress];
    }];
    
    // when
    [self.userSession registerSelfUser:registrationUser];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    NSFetchRequest *mockUserFetchRequest = [MockUser sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"name == %@ AND email == %@", registrationUser.name, registrationUser.emailAddress]];
    NSArray *userArray = [self.mockTransportSession.managedObjectContext executeFetchRequest:mockUserFetchRequest error:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(userArray.count, 1u);
    
    MockUser *user = userArray[0];
    
    MockConversation *conversation = [MockConversation conversationInMoc:self.mockTransportSession.managedObjectContext withCreator:self.selfUser otherUsers:@[user] type:ZMTConversationTypeOneOnOne];
    
    //then
    XCTAssertEqualObjects(user.email, registrationUser.emailAddress);
    XCTAssertEqualObjects(user.name, registrationUser.name);
    XCTAssertNotNil(conversation);
}

- (void)testThatRegisteringInviteeDeletesTheInvitationInSelfUser;
{
    [self.mockTransportSession logoutSelfUser];
    
    [self setupAddressBook];
    ZMAddressBookContact *invitee = self.addressBookContacts[0];
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session insertInvitationForSelfUser:self.selfUser inviteeName:invitee.name mail:invitee.emailAddresses[0]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    ZMCompleteRegistrationUser *registrationUser = [ZMCompleteRegistrationUser registrationUserWithEmail:invitee.emailAddresses[0] password:@"test123456" invitationCode:self.mockTransportSession.invitationCode];
    registrationUser.name = invitee.name;
    registrationUser.accentColorValue = ZMAccentColorSoftPink;
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:registrationUser.emailAddress];
    }];
    
    // when
    [self.userSession registerSelfUser:registrationUser];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *mockUserFetchRequest = [MockPersonalInvitation sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"inviteeName == %@ AND inviteeEmail == %@", registrationUser.name, registrationUser.emailAddress]];
    NSArray *userArray = [self.mockTransportSession.managedObjectContext executeFetchRequest:mockUserFetchRequest error:nil];
    WaitForAllGroupsToBeEmpty(0.5);

    XCTAssertEqual(userArray.count, 0lu);
}

@end
