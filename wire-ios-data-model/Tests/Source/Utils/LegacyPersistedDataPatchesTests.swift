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

import Foundation
@testable import WireDataModel
import XCTest

// MARK: - Framework comparison
class FrameworkVersionTests: XCTestCase {

    func testThatCorrectVersionsAreParsed() {

        // GIVEN
        let version = FrameworkVersion("13.5.3")

        // THEN
        XCTAssertEqual(version?.major, 13)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 3)
    }

    func testThatCorrectVersionsAreParsedWithZero() {

        // GIVEN
        let version = FrameworkVersion("0.5.0")

        // THEN
        XCTAssertEqual(version?.major, 0)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatVersionsWithNoPatchAreParsed() {

        // GIVEN
        let version = FrameworkVersion("2.5")

        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatVersionsWithNoMinorAreParsed() {

        // GIVEN
        let version = FrameworkVersion("2")

        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 0)
        XCTAssertEqual(version?.patch, 0)
    }

    func testThatEmptyVersionIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("")

        // THEN
        XCTAssertNil(version)
    }

    func testThatVersionWithTooManyIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("3.4.5.2")

        // THEN
        XCTAssertNil(version)
    }

    func testThatVersionWithTextIsNotParsed() {

        // GIVEN
        let version = FrameworkVersion("3.4.0-alpha")

        // THEN
        XCTAssertNil(version)
    }

    func testEquality() {
        XCTAssertEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertEqual(FrameworkVersion("0.2.0"), FrameworkVersion("0.2"))
        XCTAssertEqual(FrameworkVersion("0.2"), FrameworkVersion("0.2"))
        XCTAssertNotEqual(FrameworkVersion("1.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.3.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.34"))
    }

    func testComparison() {
        XCTAssertGreaterThan(FrameworkVersion("3.2.1")!, FrameworkVersion("3.2.0")!)
        XCTAssertLessThan(FrameworkVersion("3.2.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertGreaterThan(FrameworkVersion("3.3.1")!, FrameworkVersion("3.2.15")!)
        XCTAssertLessThan(FrameworkVersion("3.2.15")!, FrameworkVersion("3.3.1")!)
        XCTAssertGreaterThan(FrameworkVersion("4.0.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertLessThan(FrameworkVersion("3.2.1")!, FrameworkVersion("4.0.0")!)
        XCTAssertGreaterThan(FrameworkVersion("41.0.0")!, FrameworkVersion("0.0.1")!)
        XCTAssertLessThan(FrameworkVersion("0.0.1")!, FrameworkVersion("41.0.0")!)
    }
}

// MARK: - Test patches
class LegacyPersistedDataPatchesTests: ZMBaseManagedObjectTest {

    override class func setUp() {
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false

        super.setUp()
    }

    override class func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    override func setUp() {
        super.setUp()

        BackendInfo.domain = nil
    }

    func testThatItApplyPatchesWhenNoVersion() {

        // GIVEN
        var patchApplied = false
        let patch = LegacyPersistedDataPatch(version: "9999.32.32") { moc in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }

        // WHEN
        self.syncMOC.performGroupedAndWait {
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertTrue(patchApplied)
    }

    func testThatItApplyPatchesWhenPreviousVersionIsLesser() {

        // GIVEN
        var patchApplied = false
        let patch = LegacyPersistedDataPatch(version: "10000000.32.32") { moc in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }
        // this will bump last patched version to current version, which hopefully is less than 10000000.32.32
        self.syncMOC.performGroupedAndWait {
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        }

        // WHEN
        self.syncMOC.performGroupedAndWait {
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertTrue(patchApplied)
    }

    func testThatItDoesNotApplyPatchesWhenPreviousVersionIsGreater() {

        // GIVEN
        var patchApplied = false
        let patch = LegacyPersistedDataPatch(version: "0.0.1") { _ in
            XCTFail()
            patchApplied = true
        }
        // this will bump last patched version to current version, which is greater than 0.0.1
        self.syncMOC.performGroupedAndWait {
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        }

        // WHEN
        self.syncMOC.performGroupedAndWait {
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        }

        // THEN
        XCTAssertFalse(patchApplied, "Version: \(Bundle(for: ZMUser.self).infoDictionary!["CFBundleShortVersionString"] as! String)")
    }

    func testThatItMigratesClientsSessionIdentifiers() async throws {
        // GIVEN
        let hardcodedPrekey = "pQABAQUCoQBYIEIir0myj5MJTvs19t585RfVi1dtmL2nJsImTaNXszRwA6EAoQBYIGpa1sQFpCugwFJRfD18d9+TNJN2ZL3H0Mfj/0qZw0ruBPY="
        var selfClient: UserClient!
        var newClient: UserClient!

        await syncMOC.performGrouped {
            selfClient = self.createSelfClient(onMOC: self.syncMOC)
            let newUser = ZMUser.insertNewObject(in: self.syncMOC)
            newUser.remoteIdentifier = UUID.create()
            newClient = UserClient.insertNewObject(in: self.syncMOC)
            newClient.user = newUser
            newClient.remoteIdentifier = "aabb2d32ab"
        }

        let didEstablishSession = await selfClient.establishSessionWithClient(newClient, usingPreKey: hardcodedPrekey)
        XCTAssertTrue(didEstablishSession)

        await syncMOC.performGrouped {
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: [John] use flag here
            let otrURL = self.syncMOC.zm_cryptKeyStore.cryptoboxDirectory
            self.syncMOC.saveOrRollback()

            let sessionsURL = otrURL.appendingPathComponent("sessions")
            let oldSession = sessionsURL.appendingPathComponent(newClient.remoteIdentifier!)
            let newSession = sessionsURL.appendingPathComponent(newClient.sessionIdentifier!.rawValue)

            XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
            let previousData = try! Data(contentsOf: newSession)

            // move to fake old session
            try! FileManager.default.moveItem(at: newSession, to: oldSession)
            XCTAssertFalse(FileManager.default.fileExists(atPath: newSession.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: oldSession.path))

            // WHEN
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "0.0.0")

            // THEN
            let readData = try? Data(contentsOf: newSession)
            XCTAssertNotNil(readData)
            XCTAssertEqual(readData, previousData)
            XCTAssertFalse(FileManager.default.fileExists(atPath: oldSession.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
        }
    }

    func testThatItMigratesDegradedConversationsWithSecureWithIgnored() {
        // GIVEN
        syncMOC.performGroupedAndWait {
            let notSecureConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            notSecureConversation.conversationType = .oneOnOne
            notSecureConversation.securityLevel = .notSecure
            let secureConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            secureConversation.securityLevel = .secure
            secureConversation.conversationType = .group
            let secureWithIgnoredConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            secureWithIgnoredConversation.securityLevel = .secureWithIgnored
            secureWithIgnoredConversation.conversationType = .oneOnOne

            self.syncMOC.saveOrRollback()

            // WHEN
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "0.0.0")
            self.syncMOC.saveOrRollback()

            // THEN
            XCTAssertEqual(notSecureConversation.securityLevel, .notSecure)
            XCTAssertEqual(secureConversation.securityLevel, .secure)
            XCTAssertEqual(secureWithIgnoredConversation.securityLevel, .notSecure)
        }
    }

    func testThatItDeletesLocalTeamsAndMembers() {
        syncMOC.performGroupedAndWait {
            // given
            let moc = self.syncMOC
            let conversation = ZMConversation.insertNewObject(in: moc)
            let team = Team.insertNewObject(in: moc)
            let teamConversation = ZMConversation.insertNewObject(in: moc)
            teamConversation.team = team
            let user = ZMUser.insertNewObject(in: moc)
            user.remoteIdentifier = .create()
            let member = Member.getOrUpdateMember(for: user, in: team, context: moc)
            XCTAssert(moc.saveOrRollback())

            // when
            LegacyPersistedDataPatch.applyAll(in: moc, fromVersion: "0.0.0")
            XCTAssert(moc.saveOrRollback())

            // then
            XCTAssert(team.isZombieObject)
            XCTAssert(member.isZombieObject)
            XCTAssertFalse(conversation.isZombieObject)
            XCTAssertFalse(teamConversation.isZombieObject)

        }
    }

    func testThatItMigratesUserRemoteIdentifiersToTheirMembers() {
        syncMOC.performGroupedAndWait {
            // given
            let moc = self.syncMOC
            let userId1 = UUID.create(), userId2 = UUID.create()
            let user1 = ZMUser.insertNewObject(in: moc), user2 = ZMUser.insertNewObject(in: moc)
            user1.remoteIdentifier = userId1
            user2.remoteIdentifier = userId2
            let team = Team.insertNewObject(in: moc)

            let member1User1 = Member.getOrUpdateMember(for: user1, in: team, context: moc)
            let member2User1 = Member.getOrUpdateMember(for: user1, in: team, context: moc)
            let member1User2 = Member.getOrUpdateMember(for: user2, in: team, context: moc)
            XCTAssert(moc.saveOrRollback())

            // when
            LegacyPersistedDataPatch.applyAll(in: moc, fromVersion: "62.0.0")
            XCTAssert(moc.saveOrRollback())

            // then
            XCTAssertEqual(member1User1.remoteIdentifier, user1.remoteIdentifier)
            XCTAssertEqual(member2User1.remoteIdentifier, user1.remoteIdentifier)
            XCTAssertEqual(member1User2.remoteIdentifier, user2.remoteIdentifier)
        }
    }

    func testThatItRefetchesSelfUserDomain() {
        syncMOC.performGroupedAndWait {
            // Given
            let context = self.syncMOC

            let selfUser = ZMUser.insertNewObject(in: context)
            ZMUser.boxSelfUser(selfUser, inContextUserInfo: context)

            selfUser.remoteIdentifier = .create()
            selfUser.domain = "example.com"
            selfUser.needsToBeUpdatedFromBackend = false

            XCTAssertNotNil(selfUser.domain)
            XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend)
            XCTAssert(context.saveOrRollback())

            // When
            LegacyPersistedDataPatch.applyAll(in: context, fromVersion: "290.0.0")
            XCTAssert(context.saveOrRollback())

            // Then
            XCTAssertNil(selfUser.domain)
            XCTAssertTrue(selfUser.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Proteus session id migration

    func test_MigrateProteusSessionIDFromV2ToV3() async throws {
        await assertSuccessfulSessionMigration(simulateCryptoboxMigration: false)
    }

    func test_MigrateProteusSessionIDFromV2ToV3_WithTemporaryKeystore() async throws {
        await assertSuccessfulSessionMigration(simulateCryptoboxMigration: true)
    }

    private func assertSuccessfulSessionMigration(simulateCryptoboxMigration: Bool = false) async {
        // Given
        let hardcodedPrekey = "pQABAQUCoQBYIEIir0myj5MJTvs19t585RfVi1dtmL2nJsImTaNXszRwA6EAoQBYIGpa1sQFpCugwFJRfD18d9+TNJN2ZL3H0Mfj/0qZw0ruBPY="
        var otherUser: ZMUser!
        var selfClient: UserClient!
        var otherUserClient: UserClient!

        await syncMOC.performGrouped {
            selfClient = self.createSelfClient(onMOC: self.syncMOC)

            otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherUser.domain = nil

            otherUserClient = UserClient.insertNewObject(in: self.syncMOC)
            otherUserClient.user = otherUser
            otherUserClient.remoteIdentifier = "aabb2d32ab"
        }

        let didEstablishSession = await selfClient.establishSessionWithClient(
            otherUserClient,
            usingPreKey: hardcodedPrekey
        )
        XCTAssertTrue(didEstablishSession)

        await syncMOC.performGrouped {
            let otrURL = self.syncMOC.zm_cryptKeyStore.cryptoboxDirectory
            self.syncMOC.saveOrRollback()

            let sessionIDV2 = EncryptionSessionIdentifier(
                domain: nil,
                userId: otherUser.remoteIdentifier.uuidString,
                clientId: otherUserClient.remoteIdentifier!
            )

            let sessionIDV3 = EncryptionSessionIdentifier(
                domain: "foo.com",
                userId: otherUser.remoteIdentifier.uuidString,
                clientId: otherUserClient.remoteIdentifier!
            )

            let sessionsURL = otrURL.appendingPathComponent("sessions")
            let oldSession = sessionsURL.appendingPathComponent(sessionIDV2.rawValue)
            let newSession = sessionsURL.appendingPathComponent(sessionIDV3.rawValue)

            XCTAssertTrue(FileManager.default.fileExists(atPath: oldSession.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: newSession.path))

            let oldSessionData = try! Data(contentsOf: oldSession)

            otherUser.domain = "foo.com"
            XCTAssertTrue(otherUserClient.needsSessionMigration)

            if simulateCryptoboxMigration {
                // Delete the keystore, since we wouldn't set it up in the cryptobox
                // migration in favor of the `ProteusService` backed by Core Crypto.
                self.syncMOC.zm_tearDownCryptKeyStore()
                XCTAssertNil(self.syncMOC.zm_cryptKeyStore)
            }

            // When
            LegacyPersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "297.0.1")
            XCTAssert(self.syncMOC.saveOrRollback())

            // Then
            let newSessionData = try! Data(contentsOf: newSession)
            XCTAssertEqual(newSessionData, oldSessionData)
            XCTAssertFalse(FileManager.default.fileExists(atPath: oldSession.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
            XCTAssertFalse(otherUserClient.needsSessionMigration)

            if simulateCryptoboxMigration {
                XCTAssertNil(self.syncMOC.zm_cryptKeyStore)
            }
        }
    }

}
