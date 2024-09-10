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

@testable import WireSyncEngine
import XCTest

final class ZMUserSessionTests_SecurityClassification: ZMUserSessionTestsBase {
    func createUser(moc: NSManagedObjectContext, domain: String?) -> ZMUser {
        let user = ZMUser(context: moc)
        user.remoteIdentifier = UUID()
        user.domain = domain
        user.name = "Other Test User"

        return user
    }

    func storeClassifiedDomains(with status: Feature.Status, domains: [String]) {
        let classifiedDomains = Feature.ClassifiedDomains(
            status: status,
            config: Feature.ClassifiedDomains.Config(domains: domains)
        )
        sut.featureRepository.storeClassifiedDomains(classifiedDomains)
    }

    func testThatItReturnsNone_WhenFeatureIsEnabled_WhenSelfDomainIsNil() {
        // given
        let otherUser = createUser(moc: uiMOC, domain: UUID().uuidString)

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: [])
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = nil
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: [otherUser], conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .none)
    }

    func testThatItReturnsNone_WhenFeatureIsDisabled_WhenSelfDomainIsNotNil() {
        // given
        let otherUser = createUser(moc: uiMOC, domain: UUID().uuidString)

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .disabled, domains: [])
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: [otherUser], conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .none)
    }

    func testThatItReturnClassified_WhenFeatureIsEnabled_WhenAllOtherUserDomainIsClassified() {
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]
        let classifiedDomains = otherUsers.map { $0.domain! }

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .classified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNotClassified() {
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]

        var classifiedDomains = otherUsers.map { $0.domain! }
        classifiedDomains.removeFirst()

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNil() {
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: nil)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]

        let classifiedDomains = otherUsers.compactMap { $0.domain }

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsNotClassified_WhenFederationIsEnabled_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNil() {
        let federationFlagBackup = BackendInfo.isFederationEnabled
        let backendDomainBackup = BackendInfo.domain
        defer {
            BackendInfo.isFederationEnabled = federationFlagBackup
            BackendInfo.domain = backendDomainBackup
        }
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: nil)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]
        let localDomain = UUID().uuidString

        let otherUsersDomains = otherUsers.compactMap { $0.domain }
        let classifiedDomains = [otherUsersDomains, [localDomain]].flatMap { $0 }

        BackendInfo.isFederationEnabled = true
        BackendInfo.domain = localDomain

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsClassified_WhenFederationIsDisabled_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserDomainIsNil() {
        let federationFlagBackup = BackendInfo.isFederationEnabled
        let backendDomainBackup = BackendInfo.domain
        defer {
            BackendInfo.isFederationEnabled = federationFlagBackup
            BackendInfo.domain = backendDomainBackup
        }

        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: nil)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2, otherUser3]
        let localDomain = UUID().uuidString

        BackendInfo.isFederationEnabled = false
        BackendInfo.domain = localDomain

        let otherUsersDomains = otherUsers.compactMap { $0.domain }
        let classifiedDomains = [otherUsersDomains, [localDomain]].flatMap { $0 }

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .classified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenAtLeastOneOtherUserIsTemporary() {
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: nil)
        let otherUser3 = createUser(moc: uiMOC, domain: UUID().uuidString)
        otherUser3.expiresAt = Date(timeIntervalSinceNow: 100.0)
        let otherUsers = [otherUser1, otherUser2, otherUser3]
        let localDomain = UUID().uuidString

        let otherUsersDomains = otherUsers.compactMap { $0.domain }
        let classifiedDomains = [otherUsersDomains, [localDomain]].flatMap { $0 }

        BackendInfo.isFederationEnabled = true
        BackendInfo.domain = localDomain

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: nil)

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsNotClassified_WhenFeatureIsEnabled_WhenConversationDomainNotClassified() {
        // given
        let otherUser1 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUser2 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2]
        let localDomain = UUID().uuidString

        let otherUsersDomains = otherUsers.compactMap { $0.domain }
        let classifiedDomains = [otherUsersDomains, [localDomain]].flatMap { $0 }

        BackendInfo.isFederationEnabled = true
        BackendInfo.domain = localDomain

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: "not.Classified.Domain")

        // then
        XCTAssertEqual(classification, .notClassified)
    }

    func testThatItReturnsClassified_WhenFeatureIsEnabled_WhenConversationDomainIsClassified() {
        // given
        let otherDomain = UUID().uuidString
        let otherUser1 = createUser(moc: uiMOC, domain: otherDomain)
        let otherUser2 = createUser(moc: uiMOC, domain: UUID().uuidString)
        let otherUsers = [otherUser1, otherUser2]
        let localDomain = UUID().uuidString

        let otherUsersDomains = otherUsers.compactMap { $0.domain }
        let classifiedDomains = [otherUsersDomains, [localDomain]].flatMap { $0 }

        BackendInfo.isFederationEnabled = true
        BackendInfo.domain = localDomain

        syncMOC.performAndWait {
            storeClassifiedDomains(with: .enabled, domains: classifiedDomains)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = UUID().uuidString
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let classification = sut.classification(users: otherUsers, conversationDomain: otherDomain)

        // then
        XCTAssertEqual(classification, .classified)
    }
}
