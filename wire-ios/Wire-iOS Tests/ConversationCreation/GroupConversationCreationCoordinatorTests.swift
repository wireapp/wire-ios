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

final class GroupConversationCreationCoordinatorTests: XCTestCase {
    var sut: GroupConversationCreationCoordinator!
    var coreDataStack: CoreDataStack!
    var uiMOC: NSManagedObjectContext!
    var documentsDirectory: URL?

    override func setUp() {
        super.setUp()
        do {
            documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }
        setupCoreDataStack()
    }

    override func tearDown() {
        super.tearDown()
        sut?.finalize()
        // Needs to be called before setting self.documentsDirectory to nil.
        removeContentsOfDocumentsDirectory()
        uiMOC = nil
        coreDataStack = nil
        documentsDirectory = nil
    }

    func setupCoreDataStack() {
        let account = Account(userName: "", userIdentifier: UUID())
        let coreDataStack = CoreDataStack(account: account,
                                          applicationContainer: documentsDirectory!,
                                          inMemoryStore: true)

        coreDataStack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })
        self.coreDataStack = coreDataStack
        self.uiMOC = coreDataStack.viewContext
    }

    func removeContentsOfDocumentsDirectory() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsDirectory!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            for content: URL in contents {
                do {
                    try FileManager.default.removeItem(at: content)
                } catch {
                    XCTAssertNil(error, "Unexpected error \(error)")
                }
            }

        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

    }

    func testThatLoaderIsShownWhenConversationIsBeingCreated() {
        sut = GroupConversationCreationCoordinator(creator: MockConversationCreator())
        var showLoaderRequested = false
        _ = sut.initialize { event in
            switch event {
            case .showLoader:
                showLoaderRequested = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
            withUsers: users,
            name: "Conversation",
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            encryptionProtocol: EncryptionProtocol.proteus,
            userSession: userSession,
            moc: self.uiMOC)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(showLoaderRequested)
    }

    func testThatJustMissingLegalConsentPopupRequestIsFiredWhenNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var popupRequested = false
        var failureEmitted = false
        _ = sut.initialize { event in
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
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(popupRequested)
        XCTAssertFalse(failureEmitted)
    }

    func testThatMissingLegalConsentFailureIsEmittedWhenCompletedPopup() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var popupRequested = false
        var failureEmitted = false
        _ = sut.initialize { event in
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
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(popupRequested)
        XCTAssertTrue(failureEmitted)
    }

    func testThatJustNonFederatingBackendsPopupRequestIsFiredWhenNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var popupRequested = false
        var requestedBackends: NonFederatingBackendsTuple?
        var failureEmitted = false
        var openURLRequested = false
        _ = sut.initialize { event in
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
        let backends = NonFederatingBackendsTuple(backends: ["a", "b", "c"])
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(popupRequested)
        XCTAssertFalse(failureEmitted)
        XCTAssertFalse(openURLRequested)
        XCTAssertEqual(backends.backends, requestedBackends?.backends)
    }

    func testThatNonFederatingBackendsFailureIsEmittedWhenDiscardedCreation() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var popupRequested = false
        var requestedBackends: NonFederatingBackendsTuple?
        var failureEmitted = false
        var openURLRequested = false
        _ = sut.initialize { event in
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
        let backends = NonFederatingBackendsTuple(backends: ["a", "b", "c"])
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(popupRequested)
        XCTAssertTrue(failureEmitted)
        XCTAssertFalse(openURLRequested)
        XCTAssertEqual(backends.backends, requestedBackends?.backends)
    }

    func testThatOpenURLRequestIsEmittedWhenLearnMoreActionIsSelected() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var popupRequested = false
        var requestedBackends: NonFederatingBackendsTuple?
        var failureEmitted = false
        var openURLRequested = false
        _ = sut.initialize { event in
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
        let backends = NonFederatingBackendsTuple(backends: ["a", "b", "c"])
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(popupRequested)
        XCTAssertFalse(failureEmitted)
        XCTAssertTrue(openURLRequested)
        XCTAssertEqual(backends.backends, requestedBackends?.backends)
    }

    func testThatOtherFailureIsEmittedWhenNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var otherFailureEmitted = false
        _ = sut.initialize { event in
            switch event {
            case .failure(failureType: .other):
                otherFailureEmitted = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(otherFailureEmitted)
    }

    func testThatSuccessIsEmittedWhenConversationCreatedNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var conversationCreated = false
        _ = sut.initialize { event in
            switch event {
            case .success:
                conversationCreated = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(conversationCreated)
    }

    func testThatNoSuccessIsEmittedWhenConversationCreatedNotificationIsPostedWithAnotherConversation() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var conversationCreated = false
        _ = sut.initialize { event in
            switch event {
            case .success:
                conversationCreated = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(conversationCreated)
    }

    func testThatLoaderIsHiddenWhenConversationCreatedNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var hideLoaderRequested = false
        _ = sut.initialize { event in
            switch event {
            case .hideLoader:
                hideLoaderRequested = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(hideLoaderRequested)
    }

    func testThatLoaderIsHiddenWhenLegalConsentNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var hideLoaderRequested = false
        _ = sut.initialize { event in
            switch event {
            case .hideLoader:
                hideLoaderRequested = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(hideLoaderRequested)
    }

    func testThatLoaderIsHiddenWhenNonFederatingBackendsNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var hideLoaderRequested = false
        _ = sut.initialize { event in
            switch event {
            case .hideLoader:
                hideLoaderRequested = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let backends = NonFederatingBackendsTuple(backends: ["a", "b", "c"])
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(hideLoaderRequested)
    }

    func testThatLoaderIsHiddenWhenOtherNotificationIsPosted() {
        let creator = MockConversationCreator()
        sut = GroupConversationCreationCoordinator(creator: creator)
        var hideLoaderRequested = false
        _ = sut.initialize { event in
            switch event {
            case .hideLoader:
                hideLoaderRequested = true
            default:
                break
            }
        }
        let userSession = MockZMUserSession()
        let users = UserSet(arrayLiteral: MockUserType.createDefaultSelfUser(), MockUserType.createDefaultOtherUser())
        _ = sut.createConversation(
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
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(hideLoaderRequested)
    }
}
