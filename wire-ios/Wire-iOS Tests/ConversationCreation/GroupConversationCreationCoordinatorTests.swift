//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest
@testable import Wire
import WireTesting

class MockConversationCreator: GroupConversationCreator {
    var conversation: ZMConversation?

    init() {
    }

    func insertGroupConversation(moc: NSManagedObjectContext, participants: [ZMUser], name: String?, team: WireDataModel.Team?, allowGuests: Bool, allowServices: Bool, readReceipts: Bool, messageProtocol: WireDataModel.MessageProtocol) -> ZMConversation? {
        conversation = ZMConversation.insertGroupConversation(
            moc: moc,
            participants: participants,
            name: name,
            team: team,
            allowGuests: allowGuests,
            allowServices: allowServices,
            readReceipts: readReceipts,
            messageProtocol: messageProtocol
        )
        return conversation
    }
}

final class GroupConversationCreationCoordinatorTests: ZMTBaseTest, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var sut: GroupConversationCreationCoordinator!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        sut?.finalize()
        sut = nil
        coreDataFixture = nil
        super.tearDown()
    }

    func testThatLoaderIsShownWhenConversationIsBeingCreated() {
        do {
            sut = GroupConversationCreationCoordinator(creator: MockConversationCreator())
            var showLoaderRequested = false
            try sut.initialize { event in
                switch event {
                case .showLoader:
                    showLoaderRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(showLoaderRequested)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatJustMissingLegalConsentPopupRequestIsFiredWhenNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var popupRequested = false
            var failureEmitted = false
            try sut.initialize { event in
                switch event {
                case .presentPopup(popupType: .missingLegalHoldConsent):
                    popupRequested = true
                case .failure(failureType: .missingLegalHoldConsent):
                    failureEmitted = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.missingLegalHoldConsentNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(popupRequested)
            XCTAssertFalse(failureEmitted)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatMissingLegalConsentFailureIsEmittedWhenCompletedPopup() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var popupRequested = false
            var failureEmitted = false
            try sut.initialize { event in
                switch event {
                case .presentPopup(popupType: .missingLegalHoldConsent(let completion)):
                    popupRequested = true
                    completion()
                case .failure(failureType: .missingLegalHoldConsent):
                    failureEmitted = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.missingLegalHoldConsentNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(popupRequested)
            XCTAssertTrue(failureEmitted)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatJustNonFederatingBackendsPopupRequestIsFiredWhenNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var popupRequested = false
            var requestedBackends: NonFederatingBackends?
            var failureEmitted = false
            var openURLRequested = false
            try sut.initialize { event in
                switch event {
                case .presentPopup(popupType: .nonFederatingBackends(let backends, _)):
                    popupRequested = true
                    requestedBackends = backends
                case .failure(failureType: .nonFederatingBackends):
                    failureEmitted = true
                case .openURL:
                    openURLRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let backends = NonFederatingBackends(backends: ["a", "b", "c"])
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.nonFederatingBackendsNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!,
                    ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue: backends
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(popupRequested)
            XCTAssertFalse(failureEmitted)
            XCTAssertFalse(openURLRequested)
            XCTAssertEqual(backends.backends, requestedBackends?.backends)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatNonFederatingBackendsFailureIsEmittedWhenDiscardedCreation() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var popupRequested = false
            var requestedBackends: NonFederatingBackends?
            var failureEmitted = false
            var openURLRequested = false
            try sut.initialize { event in
                switch event {
                case .presentPopup(popupType: .nonFederatingBackends(let backends, let actionHandler)):
                    popupRequested = true
                    requestedBackends = backends
                    actionHandler(.discardGroupCreation)
                case .failure(failureType: .nonFederatingBackends):
                    failureEmitted = true
                case .openURL:
                    openURLRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let backends = NonFederatingBackends(backends: ["a", "b", "c"])
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.nonFederatingBackendsNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!,
                    ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue: backends
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(popupRequested)
            XCTAssertTrue(failureEmitted)
            XCTAssertFalse(openURLRequested)
            XCTAssertEqual(backends.backends, requestedBackends?.backends)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatOpenURLRequestIsEmittedWhenLearnMoreActionIsSelected() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var popupRequested = false
            var requestedBackends: NonFederatingBackends?
            var failureEmitted = false
            var openURLRequested = false
            try sut.initialize { event in
                switch event {
                case .presentPopup(popupType: .nonFederatingBackends(let backends, let actionHandler)):
                    popupRequested = true
                    requestedBackends = backends
                    actionHandler(.learnMore)
                case .failure(failureType: .nonFederatingBackends):
                    failureEmitted = true
                case .openURL:
                    openURLRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let backends = NonFederatingBackends(backends: ["a", "b", "c"])
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.nonFederatingBackendsNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!,
                    ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue: backends
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(popupRequested)
            XCTAssertFalse(failureEmitted)
            XCTAssertTrue(openURLRequested)
            XCTAssertEqual(backends.backends, requestedBackends?.backends)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatOtherFailureIsEmittedWhenNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var otherFailureEmitted = false
            try sut.initialize { event in
                switch event {
                case .failure(failureType: .other):
                    otherFailureEmitted = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.unknownResponseErrorNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(otherFailureEmitted)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatSuccessIsEmittedWhenConversationCreatedNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var conversationCreated = false
            try sut.initialize { event in
                switch event {
                case .success:
                    conversationCreated = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.insertedConversationUpdatedNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(conversationCreated)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatNoSuccessIsEmittedWhenConversationCreatedNotificationIsPostedWithAnotherConversation() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var conversationCreated = false
            try sut.initialize { event in
                switch event {
                case .success:
                    conversationCreated = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.insertedConversationUpdatedNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: ZMConversation()
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertFalse(conversationCreated)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatLoaderIsHiddenWhenConversationCreatedNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var hideLoaderRequested = false
            try sut.initialize { event in
                switch event {
                case .hideLoader:
                    hideLoaderRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.insertedConversationUpdatedNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 1))
            XCTAssertTrue(hideLoaderRequested)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatLoaderIsHiddenWhenLegalConsentNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var hideLoaderRequested = false
            try sut.initialize { event in
                switch event {
                case .hideLoader:
                    hideLoaderRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.missingLegalHoldConsentNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(hideLoaderRequested)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatLoaderIsHiddenWhenNonFederatingBackendsNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var hideLoaderRequested = false
            try sut.initialize { event in
                switch event {
                case .hideLoader:
                    hideLoaderRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let backends = NonFederatingBackends(backends: ["a", "b", "c"])
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.nonFederatingBackendsNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!,
                    ZMConversation.UserInfoKeys.nonFederatingBackends.rawValue: backends
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(hideLoaderRequested)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }

    func testThatLoaderIsHiddenWhenOtherNotificationIsPosted() {
        do {
            let creator = MockConversationCreator()
            sut = GroupConversationCreationCoordinator(creator: creator)
            var hideLoaderRequested = false
            try sut.initialize { event in
                switch event {
                case .hideLoader:
                    hideLoaderRequested = true
                default:
                    break
                }
            }
            let userSession = MockZMUserSession()
            let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
            try sut.createConversation(
                withUsers: users,
                name: "Conversation",
                allowGuests: true,
                allowServices: true,
                enableReceipts: true,
                encryptionProtocol: EncryptionProtocol.proteus,
                userSession: userSession,
                moc: self.uiMOC)
            NotificationCenter.default.post(
                name: ZMConversation.unknownResponseErrorNotificationName,
                object: self.uiMOC,
                userInfo: [
                    NotificationInContext.objectInNotificationKey: creator.conversation!
                ]
            )
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(hideLoaderRequested)
        } catch {
            XCTFail("Conversation creation failure")
        }
    }
}
