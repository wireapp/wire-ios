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
@testable import WireSyncEngine

public class MockFeatureRepositoryInterface: FeatureRepositoryInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - fetchAppLock

    public var fetchAppLock_Invocations: [Void] = []
    public var fetchAppLock_MockMethod: (() -> Feature.AppLock)?
    public var fetchAppLock_MockValue: Feature.AppLock?

    public func fetchAppLock() -> Feature.AppLock {
        fetchAppLock_Invocations.append(())

        if let mock = fetchAppLock_MockMethod {
            return mock()
        } else if let mock = fetchAppLock_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAppLock`")
        }
    }

    // MARK: - storeAppLock

    public var storeAppLock_Invocations: [Feature.AppLock] = []
    public var storeAppLock_MockMethod: ((Feature.AppLock) -> Void)?

    public func storeAppLock(_ appLock: Feature.AppLock) {
        storeAppLock_Invocations.append(appLock)

        guard let mock = storeAppLock_MockMethod else {
            fatalError("no mock for `storeAppLock`")
        }

        mock(appLock)
    }

    // MARK: - fetchConferenceCalling

    public var fetchConferenceCalling_Invocations: [Void] = []
    public var fetchConferenceCalling_MockMethod: (() -> Feature.ConferenceCalling)?
    public var fetchConferenceCalling_MockValue: Feature.ConferenceCalling?

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        fetchConferenceCalling_Invocations.append(())

        if let mock = fetchConferenceCalling_MockMethod {
            return mock()
        } else if let mock = fetchConferenceCalling_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConferenceCalling`")
        }
    }

    // MARK: - storeConferenceCalling

    public var storeConferenceCalling_Invocations: [Feature.ConferenceCalling] = []
    public var storeConferenceCalling_MockMethod: ((Feature.ConferenceCalling) -> Void)?

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        storeConferenceCalling_Invocations.append(conferenceCalling)

        guard let mock = storeConferenceCalling_MockMethod else {
            fatalError("no mock for `storeConferenceCalling`")
        }

        mock(conferenceCalling)
    }

    // MARK: - fetchFileSharing

    public var fetchFileSharing_Invocations: [Void] = []
    public var fetchFileSharing_MockMethod: (() -> Feature.FileSharing)?
    public var fetchFileSharing_MockValue: Feature.FileSharing?

    public func fetchFileSharing() -> Feature.FileSharing {
        fetchFileSharing_Invocations.append(())

        if let mock = fetchFileSharing_MockMethod {
            return mock()
        } else if let mock = fetchFileSharing_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchFileSharing`")
        }
    }

    // MARK: - storeFileSharing

    public var storeFileSharing_Invocations: [Feature.FileSharing] = []
    public var storeFileSharing_MockMethod: ((Feature.FileSharing) -> Void)?

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        storeFileSharing_Invocations.append(fileSharing)

        guard let mock = storeFileSharing_MockMethod else {
            fatalError("no mock for `storeFileSharing`")
        }

        mock(fileSharing)
    }

    // MARK: - fetchSelfDeletingMesssages

    public var fetchSelfDeletingMesssages_Invocations: [Void] = []
    public var fetchSelfDeletingMesssages_MockMethod: (() -> Feature.SelfDeletingMessages)?
    public var fetchSelfDeletingMesssages_MockValue: Feature.SelfDeletingMessages?

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        fetchSelfDeletingMesssages_Invocations.append(())

        if let mock = fetchSelfDeletingMesssages_MockMethod {
            return mock()
        } else if let mock = fetchSelfDeletingMesssages_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfDeletingMesssages`")
        }
    }

    // MARK: - storeSelfDeletingMessages

    public var storeSelfDeletingMessages_Invocations: [Feature.SelfDeletingMessages] = []
    public var storeSelfDeletingMessages_MockMethod: ((Feature.SelfDeletingMessages) -> Void)?

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        storeSelfDeletingMessages_Invocations.append(selfDeletingMessages)

        guard let mock = storeSelfDeletingMessages_MockMethod else {
            fatalError("no mock for `storeSelfDeletingMessages`")
        }

        mock(selfDeletingMessages)
    }

    // MARK: - fetchConversationGuestLinks

    public var fetchConversationGuestLinks_Invocations: [Void] = []
    public var fetchConversationGuestLinks_MockMethod: (() -> Feature.ConversationGuestLinks)?
    public var fetchConversationGuestLinks_MockValue: Feature.ConversationGuestLinks?

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        fetchConversationGuestLinks_Invocations.append(())

        if let mock = fetchConversationGuestLinks_MockMethod {
            return mock()
        } else if let mock = fetchConversationGuestLinks_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGuestLinks`")
        }
    }

    // MARK: - storeConversationGuestLinks

    public var storeConversationGuestLinks_Invocations: [Feature.ConversationGuestLinks] = []
    public var storeConversationGuestLinks_MockMethod: ((Feature.ConversationGuestLinks) -> Void)?

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        storeConversationGuestLinks_Invocations.append(conversationGuestLinks)

        guard let mock = storeConversationGuestLinks_MockMethod else {
            fatalError("no mock for `storeConversationGuestLinks`")
        }

        mock(conversationGuestLinks)
    }

    // MARK: - fetchClassifiedDomains

    public var fetchClassifiedDomains_Invocations: [Void] = []
    public var fetchClassifiedDomains_MockMethod: (() -> Feature.ClassifiedDomains)?
    public var fetchClassifiedDomains_MockValue: Feature.ClassifiedDomains?

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        fetchClassifiedDomains_Invocations.append(())

        if let mock = fetchClassifiedDomains_MockMethod {
            return mock()
        } else if let mock = fetchClassifiedDomains_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchClassifiedDomains`")
        }
    }

    // MARK: - storeClassifiedDomains

    public var storeClassifiedDomains_Invocations: [Feature.ClassifiedDomains] = []
    public var storeClassifiedDomains_MockMethod: ((Feature.ClassifiedDomains) -> Void)?

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        storeClassifiedDomains_Invocations.append(classifiedDomains)

        guard let mock = storeClassifiedDomains_MockMethod else {
            fatalError("no mock for `storeClassifiedDomains`")
        }

        mock(classifiedDomains)
    }

    // MARK: - fetchDigitalSignature

    public var fetchDigitalSignature_Invocations: [Void] = []
    public var fetchDigitalSignature_MockMethod: (() -> Feature.DigitalSignature)?
    public var fetchDigitalSignature_MockValue: Feature.DigitalSignature?

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        fetchDigitalSignature_Invocations.append(())

        if let mock = fetchDigitalSignature_MockMethod {
            return mock()
        } else if let mock = fetchDigitalSignature_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchDigitalSignature`")
        }
    }

    // MARK: - storeDigitalSignature

    public var storeDigitalSignature_Invocations: [Feature.DigitalSignature] = []
    public var storeDigitalSignature_MockMethod: ((Feature.DigitalSignature) -> Void)?

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        storeDigitalSignature_Invocations.append(digitalSignature)

        guard let mock = storeDigitalSignature_MockMethod else {
            fatalError("no mock for `storeDigitalSignature`")
        }

        mock(digitalSignature)
    }

    // MARK: - fetchMLS

    public var fetchMLS_Invocations: [Void] = []
    public var fetchMLS_MockMethod: (() -> Feature.MLS)?
    public var fetchMLS_MockValue: Feature.MLS?

    public func fetchMLS() -> Feature.MLS {
        fetchMLS_Invocations.append(())

        if let mock = fetchMLS_MockMethod {
            return mock()
        } else if let mock = fetchMLS_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLS`")
        }
    }

    // MARK: - storeMLS

    public var storeMLS_Invocations: [Feature.MLS] = []
    public var storeMLS_MockMethod: ((Feature.MLS) -> Void)?

    public func storeMLS(_ mls: Feature.MLS) {
        storeMLS_Invocations.append(mls)

        guard let mock = storeMLS_MockMethod else {
            fatalError("no mock for `storeMLS`")
        }

        mock(mls)
    }

    // MARK: - fetchMLSMigration

    public var fetchMLSMigration_Invocations: [Void] = []
    public var fetchMLSMigration_MockMethod: (() -> Feature.MLSMigration)?
    public var fetchMLSMigration_MockValue: Feature.MLSMigration?

    public func fetchMLSMigration() -> Feature.MLSMigration {
        fetchMLSMigration_Invocations.append(())

        if let mock = fetchMLSMigration_MockMethod {
            return mock()
        } else if let mock = fetchMLSMigration_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLSMigration`")
        }
    }

    // MARK: - storeMLSMigration

    public var storeMLSMigration_Invocations: [Feature.MLSMigration] = []
    public var storeMLSMigration_MockMethod: ((Feature.MLSMigration) -> Void)?

    public func storeMLSMigration(_ mlsMigration: Feature.MLSMigration) {
        storeMLSMigration_Invocations.append(mlsMigration)

        guard let mock = storeMLSMigration_MockMethod else {
            fatalError("no mock for `storeMLSMigration`")
        }

        mock(mlsMigration)
    }

}
