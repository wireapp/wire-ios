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

struct FeatureConfigsPayloadProcessor {

    private let jsonDecoder = JSONDecoder.defaultDecoder

    func processPayloadData(_ data: Data, featureRepository: FeatureRepositoryInterface) throws {
        let payload = try jsonDecoder.decode(FeatureConfigsPayload.self, from: data)

        if let appLock = payload.appLock {
            featureRepository.storeAppLock(
                Feature.AppLock(
                    status: appLock.status,
                    config: appLock.config
                )
            )
        }

        if let classifiedDomains = payload.classifiedDomains {
            featureRepository.storeClassifiedDomains(
                Feature.ClassifiedDomains(
                    status: classifiedDomains.status,
                    config: classifiedDomains.config
                )
            )
        }

        if let conferenceCalling = payload.conferenceCalling {
            featureRepository.storeConferenceCalling(
                Feature.ConferenceCalling(
                    status: conferenceCalling.status
                )
            )
        }

        if let conversationGuestLinks = payload.conversationGuestLinks {
            featureRepository.storeConversationGuestLinks(
                Feature.ConversationGuestLinks(
                    status: conversationGuestLinks.status
                )
            )
        }

        if let digitalSignatures = payload.digitalSignatures {
            featureRepository.storeDigitalSignature(
                Feature.DigitalSignature(
                    status: digitalSignatures.status
                )
            )
        }

        if let fileSharing = payload.fileSharing {
            featureRepository.storeFileSharing(
                Feature.FileSharing(
                    status: fileSharing.status
                )
            )
        }

        if let mls = payload.mls {
            featureRepository.storeMLS(
                Feature.MLS(
                    status: mls.status,
                    config: mls.config
                )
            )
        }

        if let mlsMigration = payload.mlsMigration {
            featureRepository.storeMLSMigration(
                Feature.MLSMigration(
                    status: mlsMigration.status,
                    config: mlsMigration.config
                )
            )
        }

        if let selfDeletingMessages = payload.selfDeletingMessages {
            featureRepository.storeSelfDeletingMessages(
                Feature.SelfDeletingMessages(
                    status: selfDeletingMessages.status,
                    config: selfDeletingMessages.config
                )
            )
        }

        if let mlsMigration = payload.mlsMigration {
            featureRepository.storeMLSMigration(
                Feature.MLSMigration(
                    status: mlsMigration.status,
                    config: mlsMigration.config
                )
            )
        }
    }
}
