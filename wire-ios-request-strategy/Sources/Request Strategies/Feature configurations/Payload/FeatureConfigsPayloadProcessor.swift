//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import protocol WireDataModel.LegacyFeatureRepositoryInterface
import WireLogging

struct FeatureConfigsPayloadProcessor {

    private let decoder = JSONDecoder.defaultDecoder
    private let apiVersion: WireTransport.APIVersion?

    init(apiVersion: WireTransport.APIVersion?) {
        self.apiVersion = apiVersion
    }

    func processActionPayload(data: Data, repository: LegacyFeatureRepositoryInterface) throws {
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

    func processActionPayloadAPIV6(data: Data, repository: LegacyFeatureRepositoryInterface) throws {
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

}
