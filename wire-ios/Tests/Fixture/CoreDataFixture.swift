//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireFoundation
import XCTest
@testable import Wire
@testable import WireDataModel

// MARK: - CoreDataFixture

/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
final class CoreDataFixture {
    // MARK: Lifecycle

    init() {
        /// From ZMSnapshotTestCase

        XCTAssertEqual(UIScreen.main.scale, 3, "Snapshot tests need to be run on a device with a 3x scale")
        if UIDevice.current.systemVersion
            .compare("17", options: .numeric, range: nil, locale: .current) == .orderedAscending {
            XCTFail("Snapshot tests need to be run on a device running at least iOS 17")
        }
        AppRootRouter.configureAppearance()
        UIView.setAnimationsEnabled(false)
        self.snapshotBackgroundColor = UIColor.clear

        do {
            self.documentsDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

        let account = Account(userName: "", userIdentifier: UUID())
        let group = ZMSDispatchGroup(dispatchGroup: dispatchGroup, label: "CoreDataStack")
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: documentsDirectory!,
            inMemoryStore: true,
            dispatchGroup: group
        )

        coreDataStack.loadStores(completionHandler: { _ in })
        self.uiMOC = coreDataStack.viewContext
        self.coreDataStack = coreDataStack

        if needsCaches {
            setUpCaches()
        }

        /////////////////////////

        self.snapshotBackgroundColor = .white
        setupTestObjects()

        MockUser.setMockSelf(selfUser)
        self.selfUserProvider = SelfProvider(providedSelfUser: selfUser)

        SelfUser.provider = selfUserProvider
    }

    deinit {
        SelfUser.provider = nil
        selfUser = nil
        otherUser = nil
        otherUserConversation = nil
        teamMember = nil
        team = nil

        MockUser.setMockSelf(nil)
    }

    // MARK: Internal

    /// From ZMSnapshot

    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    var team: Team?
    var teamMember: Member?
    let usernames = [
        "Anna",
        "Claire",
        "Dean",
        "Erik",
        "Frank",
        "Gregor",
        "Hanna",
        "Inge",
        "James",
        "Laura",
        "Klaus",
        "Lena",
        "Linea",
        "Lara",
        "Elliot",
        "Francois",
        "Felix",
        "Brian",
        "Brett",
        "Hannah",
        "Ana",
        "Paula",
    ]

    // The provider to use when configuring `SelfUser.provider`, needed only when tested code
    // invokes `SelfUser.current`. As we slowly migrate to `UserType`, we will use this more
    // and the `var selfUser: ZMUser!` less.
    //
    var selfUserProvider: SelfUserProvider!

    let dispatchGroup = DispatchGroup()
    var uiMOC: NSManagedObjectContext!
    var coreDataStack: CoreDataStack!

    /// The color of the container view in which the view to
    /// be snapshot will be placed, defaults to UIColor.lightGrayColor
    var snapshotBackgroundColor: UIColor?

    var documentsDirectory: URL?

    /// If YES the uiMOC will have image and file caches. Defaults to NO.
    var needsCaches: Bool {
        false
    }

    func setUpCaches() {
        let cacheLocation = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        uiMOC.zm_userImageCache = UserImageLocalCache(location: nil)
        uiMOC.zm_fileAssetCache = FileAssetCache(location: cacheLocation)
    }

    func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }

    func createService(name: String) -> ZMUser {
        let user = createUser(name: name)
        user.serviceIdentifier = UUID.create().transportString()
        user.providerIdentifier = UUID.create().transportString()
        return user
    }

    func nonTeamTest(_ block: () throws -> Void) rethrows {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = false
        updateTeamStatus(wasInTeam: wasInTeam)
        try block()
    }

    func teamTest(_ block: () throws -> Void) rethrows {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = true
        updateTeamStatus(wasInTeam: wasInTeam)
        try block()
    }

    func markAllMessagesAsUnread(in conversation: ZMConversation) {
        conversation.lastReadServerTimeStamp = Date.distantPast
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
    }

    // MARK: Private

    private var selfUserInTeam = false

    // MARK: – Setup

    private func setupMember() {
        let selfUser = ZMUser.selfUser(in: uiMOC)

        team = Team.insertNewObject(in: uiMOC)
        team!.remoteIdentifier = UUID()

        teamMember = Member.insertNewObject(in: uiMOC)
        teamMember!.user = selfUser
        teamMember!.team = team
        teamMember!.setTeamRole(.member)
    }

    private func setupTestObjects() {
        selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        selfUser.accentColor = .red
        selfUser.emailAddress = "test@email.com"
        selfUser.phoneNumber = "+123456789"

        if selfUserInTeam {
            setupMember()
        }

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.handle = "bruno"
        otherUser.accentColor = .amber

        otherUserConversation = ZMConversation.createOtherUserConversation(moc: uiMOC, otherUser: otherUser)

        uiMOC.saveOrRollback()
    }

    private func updateTeamStatus(wasInTeam: Bool) {
        guard wasInTeam != selfUserInTeam else {
            return
        }

        if selfUserInTeam {
            setupMember()
        } else {
            teamMember = nil
            team = nil
        }
    }
}

// MARK: - mock service user

extension CoreDataFixture {
    func createServiceUser() -> ZMUser {
        let serviceUser = ZMUser.insertNewObject(in: uiMOC)
        serviceUser.remoteIdentifier = UUID()
        serviceUser.name = "ServiceUser"
        serviceUser.handle = serviceUser.name!.lowercased()
        serviceUser.accentColor = .amber
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        uiMOC.saveOrRollback()

        return serviceUser
    }
}

// MARK: - CoreDataFixtureTestHelper

protocol CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture! { get }

    /// with default implementation
    var otherUser: ZMUser! { get }
    var selfUser: ZMUser! { get }

    var otherUserConversation: ZMConversation! { get }

    func createGroupConversation() -> ZMConversation
    func createTeamGroupConversation() -> ZMConversation

    func createUser(name: String) -> ZMUser

    func teamTest(_ block: () -> Void)

    func mockUserClient() -> UserClient!

    func createGroupConversationOnlyAdmin() -> ZMConversation
}

// MARK: - default implementation for migrating CoreDataSnapshotTestCase to XCTestCase

extension CoreDataFixtureTestHelper {
    var otherUser: ZMUser! {
        coreDataFixture.otherUser
    }

    var selfUser: ZMUser! {
        coreDataFixture.selfUser
    }

    var otherUserConversation: ZMConversation! {
        coreDataFixture.otherUserConversation
    }

    func createGroupConversation() -> ZMConversation {
        ZMConversation.createGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: otherUser,
            selfUser: selfUser
        )
    }

    func createTeamGroupConversation() -> ZMConversation {
        ZMConversation.createTeamGroupConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    func createUser(name: String) -> ZMUser {
        coreDataFixture.createUser(name: name)
    }

    func teamTest(_ block: () -> Void) {
        coreDataFixture.teamTest(block)
    }

    func nonTeamTest(_ block: () -> Void) {
        coreDataFixture.nonTeamTest(block)
    }

    var uiMOC: NSManagedObjectContext! {
        coreDataFixture.uiMOC
    }

    var usernames: [String] {
        coreDataFixture.usernames
    }

    var team: Team? {
        coreDataFixture.team
    }

    func mockUserClient() -> UserClient! {
        coreDataFixture.mockUserClient()
    }

    func createGroupConversationOnlyAdmin() -> ZMConversation {
        ZMConversation.createGroupConversationOnlyAdmin(moc: uiMOC, selfUser: selfUser)
    }
}

extension CoreDataFixture {
    func mockUserClient() -> UserClient! {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"

        client.user = ZMUser.insertNewObject(in: uiMOC)
        client.deviceClass = .tablet
        client.model = "Simulator"
        client.label = "Bill's MacBook Pro"

        client.activationDate = Date(timeIntervalSince1970: 1_664_717_723)
        return client
    }
}

extension UIColor {
    private class var accentOverrideColor: AccentColor? {
        ZMUser.selfUser()?.accentColor
    }
}
