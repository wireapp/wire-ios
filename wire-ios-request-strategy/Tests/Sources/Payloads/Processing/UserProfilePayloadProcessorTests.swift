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
import WireTransport
import XCTest

@testable import WireRequestStrategy

final class UserProfilePayloadProcessorTests: MessagingTestBase {

    var sut: UserProfilePayloadProcessor!

    override func setUp() {
        super.setUp()
        sut = UserProfilePayloadProcessor()

        syncMOC.performGroupedAndWait {
            self.otherUser.remoteIdentifier = nil
            self.otherUser.domain = nil
        }
        BackendInfo.isFederationEnabled = false
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testUpdateUserProfile_UpdatesID() throws {
        syncMOC.performGroupedAndWait {
            // given
            let userProfile = Payload.UserProfile(id: UUID())

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, userProfile.id)
        }
    }

    func testUpdateUserProfile_UpdatesQualifiedUserID() throws {
        syncMOC.performGroupedAndWait {
            // given
            BackendInfo.isFederationEnabled = true
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, qualifiedID.uuid)
            XCTAssertEqual(self.otherUser.domain, qualifiedID.domain)
        }
    }

    func testUpdateUserProfile_DoesntUpdatesQualifiedUserID_WhenFederationIsDisabled() throws {
        syncMOC.performGroupedAndWait {
            // given
            BackendInfo.isFederationEnabled = false
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(id: qualifiedID.uuid, qualifiedID: qualifiedID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, qualifiedID.uuid)
            XCTAssertNil(self.otherUser.domain)
        }
    }

    func testUpdateUserProfile_UpdatesTeamID() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, teamID: UUID())

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.teamIdentifier, userProfile.teamID)
        }
    }

    func testUpdateUserProfile_TeamIDCanBeDeleted_ByNonAuthoritativeUpdate() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, updatedKeys: [.teamID])

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: false
            )

            // then
            XCTAssertNil(self.otherUser.teamIdentifier)
        }
    }

    func testUpdateUserProfile_TeamMembershipIsCreated_WhenUserBelongsToSelfUserTeam() throws {
        syncMOC.performGroupedAndWait {
            // given
            let teamID = UUID()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamID
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, teamID: teamID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.membership?.team, team)
        }
    }

    func testUpdateUserProfile_UpdatesServiceID() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let serviceID = Payload.ServiceID(id: UUID(), provider: UUID())
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, serviceID: serviceID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.serviceIdentifier, serviceID.id.transportString())
            XCTAssertEqual(self.otherUser.providerIdentifier, serviceID.provider.transportString())
        }
    }

    func testUpdateUserProfile_UpdatesSSOID() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let SSOID = Payload.SSOID(tenant: "a", subject: "b", scimExternalID: "c")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, SSOID: SSOID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertTrue(self.otherUser.usesCompanyLogin)
        }
    }

    func testUpdateUserProfile_UpdatesName() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let name = "John Doe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: name)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.name, name)
        }
    }

    func testUpdateUserProfile_NameIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedAndWait {
            // given
            let oldName = "John Doe"
            let newName = "Nhoj Eod"
            self.otherUser.name = oldName
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: newName)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.name, oldName)
        }
    }

    func testUpdateUserProfile_UpdatesHandle() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let handle = "johndoe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, handle: handle)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.handle, handle)
        }
    }

    func testUpdateUserProfile_HandleIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedAndWait {
            // given
            let oldHandle = "johndoe"
            let newhandle = "eodnhoj"
            self.otherUser.handle = oldHandle
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, handle: newhandle)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.handle, oldHandle)
        }
    }

    func testUpdateUserProfile_UpdatesEmail() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let email = "john.doe@example.com"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, email: email)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.emailAddress, email)
        }
    }

    func testUpdateUserProfile_EmailCanBeDeleted_ByNonAuthoritativeUpdate() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let updatedKeysSet: Set<Payload.UserProfile.CodingKeys> = [.email]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, updatedKeys: updatedKeysSet)
            self.otherUser.emailAddress = "john.doe@example.com"

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: false
            )

            // then
            XCTAssertNil(self.otherUser.emailAddress)
        }
    }

    func testUpdateUserProfile_EmailIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedAndWait {
            // given
            let oldEmail = "john.doe@example.com"
            let newEmail = "john.eod@example.com"
            self.otherUser.emailAddress = oldEmail
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, email: newEmail)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.emailAddress, oldEmail)
        }
    }

    func testUpdateUserProfile_UpdatesAssets() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let previewAsset = Payload.Asset(key: "1", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.previewProfileAssetIdentifier, previewAsset.key)
            XCTAssertEqual(self.otherUser.completeProfileAssetIdentifier, completeAsset.key)
        }
    }

    func testUpdateUserProfile_AssetsIsNotUpdated_WhenAssetsHaveLocalChanges() throws {
        syncMOC.performGroupedAndWait {
            // given
            let assetsModifiedKeys = [ZMUser.previewProfileAssetIdentifierKey,
                                      ZMUser.completeProfileAssetIdentifierKey]
            let oldPreviewAssetKey = "a"
            let oldCompleteAssetKey = "b"
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.previewProfileAssetIdentifier = oldPreviewAssetKey
            selfUser.completeProfileAssetIdentifier = oldCompleteAssetKey
            selfUser.setLocallyModifiedKeys(Set(assetsModifiedKeys))
            let qualifiedID = QualifiedID(uuid: selfUser.remoteIdentifier, domain: "example.com")
            let previewAsset = Payload.Asset(key: "1", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: selfUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(selfUser.previewProfileAssetIdentifier, oldPreviewAssetKey)
            XCTAssertEqual(selfUser.completeProfileAssetIdentifier, oldCompleteAssetKey)
        }
    }

    func testUpdateUserProfile_AssetsAreRejected_WhenAssetsKeysAreInvalid() throws {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.previewProfileAssetIdentifier = "a"
            self.otherUser.completeProfileAssetIdentifier = "b"
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let previewAsset = Payload.Asset(key: "1<", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2\"", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertNil(self.otherUser.previewProfileAssetIdentifier)
            XCTAssertNil(self.otherUser.completeProfileAssetIdentifier)
        }
    }

    func testUpdateUserProfile_UpdatesManagedBy() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let managedBy = "wire"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, managedBy: managedBy)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertTrue(self.otherUser.managedByWire)
        }
    }

    func testUpdateUserProfile_UpdatesAccentColor() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let accentColor = AccentColor(rawValue: 5)
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, accentColor: Int(accentColor!.rawValue))

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.accentColor, accentColor)
        }
    }

    func testUpdateUserProfile_UpdatesIsDeleted() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, isDeleted: true)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertTrue(self.otherUser.isAccountDeleted)
        }
    }

    func testUpdateUserProfile_UpdatesExpiresAt() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let expiresAt = Date()
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, expiresAt: expiresAt)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertEqual(self.otherUser.expiresAt, expiresAt)
        }
    }

    func testUpdateUserProfiles_AppliesUpdateOnUserProfileList() throws {
        syncMOC.performGroupedAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let name = "John Doe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: name)
            self.otherUser.remoteIdentifier = qualifiedID.uuid
            self.otherUser.domain = qualifiedID.domain
            self.syncMOC.saveOrRollback()

            // when
            self.sut.updateUserProfiles(
                from: [userProfile],
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(self.otherUser.name, name)
        }
    }

    func testUpdateUserProfile_UpdatesIsPendingMetadataRefresh() throws {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.isPendingMetadataRefresh = true
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID)

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser,
                authoritative: true
            )

            // then
            XCTAssertFalse(self.otherUser.isPendingMetadataRefresh)
        }
    }

    func testUpdateUserProfile_UpdatesSupportedProtocols() throws {
        syncMOC.performGroupedAndWait {
            // given
            XCTAssertEqual(self.otherUser.supportedProtocols, [])
            let userProfile = Payload.UserProfile(supportedProtocols: [.proteus, .mls])

            // when
            self.sut.updateUserProfile(
                from: userProfile,
                for: self.otherUser
            )

            // then
            XCTAssertEqual(self.otherUser.supportedProtocols, [.proteus, .mls])
        }
    }

}
