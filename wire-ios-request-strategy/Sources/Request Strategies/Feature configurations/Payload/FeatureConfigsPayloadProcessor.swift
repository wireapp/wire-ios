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
import protocol WireDataModel.FeatureRepositoryInterface

struct FeatureConfigsPayloadProcessor {
    // MARK: Internal

    func processActionPayload(data: Data, repository: FeatureRepositoryInterface) throws {
        let payload = try decoder.decode(FeatureConfigsPayload.self, from: data)

        if let appLock = payload.appLock {
            repository.storeAppLock(
                Feature.AppLock(
                    status: appLock.status,
                    config: appLock.config
                )
            )
        }

        if let classifiedDomains = payload.classifiedDomains {
            repository.storeClassifiedDomains(
                Feature.ClassifiedDomains(
                    status: classifiedDomains.status,
                    config: classifiedDomains.config
                )
            )
        }

        if let conferenceCalling = payload.conferenceCalling {
            repository.storeConferenceCalling(
                Feature.ConferenceCalling(
                    status: conferenceCalling.status
                )
            )
        }

        if let conversationGuestLinks = payload.conversationGuestLinks {
            repository.storeConversationGuestLinks(
                Feature.ConversationGuestLinks(
                    status: conversationGuestLinks.status
                )
            )
        }

        if let digitalSignatures = payload.digitalSignatures {
            repository.storeDigitalSignature(
                Feature.DigitalSignature(
                    status: digitalSignatures.status
                )
            )
        }

        if let fileSharing = payload.fileSharing {
            repository.storeFileSharing(
                Feature.FileSharing(
                    status: fileSharing.status
                )
            )
        }

        if let mls = payload.mls {
            repository.storeMLS(
                Feature.MLS(
                    status: mls.status,
                    config: mls.config
                )
            )
        }

        if let selfDeletingMessages = payload.selfDeletingMessages {
            repository.storeSelfDeletingMessages(
                Feature.SelfDeletingMessages(
                    status: selfDeletingMessages.status,
                    config: selfDeletingMessages.config
                )
            )
        }

        if let mlsMigration = payload.mlsMigration {
            repository.storeMLSMigration(
                Feature.MLSMigration(
                    status: mlsMigration.status,
                    config: mlsMigration.config
                )
            )
        }

        if let e2ei = payload.mlsE2EId {
            repository.storeE2EI(
                Feature.E2EI(
                    status: e2ei.status,
                    config: e2ei.config
                )
            )
        }
    }

    func processActionPayloadAPIV6(data: Data, repository: FeatureRepositoryInterface) throws {
        let payload = try decoder.decode(FeatureConfigsPayloadAPIV6.self, from: data)

        if let appLock = payload.appLock {
            repository.storeAppLock(
                Feature.AppLock(
                    status: appLock.status,
                    config: appLock.config
                )
            )
        }

        if let classifiedDomains = payload.classifiedDomains {
            repository.storeClassifiedDomains(
                Feature.ClassifiedDomains(
                    status: classifiedDomains.status,
                    config: classifiedDomains.config
                )
            )
        }

        if let conferenceCalling = payload.conferenceCalling {
            repository.storeConferenceCalling(
                Feature.ConferenceCalling(
                    status: conferenceCalling.status,
                    config: conferenceCalling.config
                )
            )
        }

        if let conversationGuestLinks = payload.conversationGuestLinks {
            repository.storeConversationGuestLinks(
                Feature.ConversationGuestLinks(
                    status: conversationGuestLinks.status
                )
            )
        }

        if let digitalSignatures = payload.digitalSignatures {
            repository.storeDigitalSignature(
                Feature.DigitalSignature(
                    status: digitalSignatures.status
                )
            )
        }

        if let fileSharing = payload.fileSharing {
            repository.storeFileSharing(
                Feature.FileSharing(
                    status: fileSharing.status
                )
            )
        }

        if let mls = payload.mls {
            repository.storeMLS(
                Feature.MLS(
                    status: mls.status,
                    config: mls.config
                )
            )
        }

        if let selfDeletingMessages = payload.selfDeletingMessages {
            repository.storeSelfDeletingMessages(
                Feature.SelfDeletingMessages(
                    status: selfDeletingMessages.status,
                    config: selfDeletingMessages.config
                )
            )
        }

        if let mlsMigration = payload.mlsMigration {
            repository.storeMLSMigration(
                Feature.MLSMigration(
                    status: mlsMigration.status,
                    config: mlsMigration.config
                )
            )
        }

        if let e2ei = payload.mlsE2EId {
            repository.storeE2EI(
                Feature.E2EI(
                    status: e2ei.status,
                    config: e2ei.config
                )
            )
        }
    }

    func processEventPayload(
        data: Data,
        featureName: Feature.Name,
        repository: FeatureRepositoryInterface
    ) throws {
        switch featureName {
        case .conferenceCalling:
            if let apiVersion = BackendInfo.apiVersion,
               apiVersion >= .v6 {
                let response = try decoder.decode(
                    FeatureStatusWithConfig<Feature.ConferenceCalling.Config>.self,
                    from: data
                )
                repository.storeConferenceCalling(.init(status: response.status, config: response.config))
            } else {
                let response = try decoder.decode(FeatureStatus.self, from: data)
                repository.storeConferenceCalling(.init(status: response.status))
            }

        case .fileSharing:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            repository.storeFileSharing(.init(status: response.status))

        case .appLock:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.AppLock.Config>.self, from: data)
            repository.storeAppLock(.init(status: response.status, config: response.config))

        case .selfDeletingMessages:
            let response = try decoder.decode(
                FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>.self,
                from: data
            )
            repository.storeSelfDeletingMessages(.init(status: response.status, config: response.config))

        case .conversationGuestLinks:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            repository.storeConversationGuestLinks(.init(status: response.status))

        case .classifiedDomains:
            let response = try decoder.decode(
                FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>.self,
                from: data
            )
            repository.storeClassifiedDomains(.init(status: response.status, config: response.config))

        case .digitalSignature:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            repository.storeDigitalSignature(.init(status: response.status))

        case .mls:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.MLS.Config>.self, from: data)
            repository.storeMLS(.init(status: response.status, config: response.config))

        case .mlsMigration:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.MLSMigration.Config>.self, from: data)
            repository.storeMLSMigration(.init(status: response.status, config: response.config))

        case .e2ei:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.E2EI.Config>.self, from: data)
            repository.storeE2EI(.init(status: response.status, config: response.config))
        }
    }

    // MARK: Private

    private let decoder = JSONDecoder.defaultDecoder
}
