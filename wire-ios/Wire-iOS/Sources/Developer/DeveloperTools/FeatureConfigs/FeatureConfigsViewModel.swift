//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireSyncEngine

final class FeatureConfigsViewModel: ObservableObject {

    enum FeatureConfigName: String {
        case mls
        case conferenceCalling
        case e2EI
        case allowedGlobalOperations
        case appLock
        case channels
        case classifiedDomains
        case consumableNotifications
        case conversationGuestLinks
        case fileSharing
        case selfDeletingMessages
        case digitalSignature
    }

    enum FeatureConfigStatus: String {
        case enabled
        case disabled

        init(status: Feature.Status) {
            switch status {
            case .enabled:
                self = .enabled
            case .disabled:
                self = .disabled
            }
        }
    }

    struct Item: Identifiable {
        let featureConfigName: FeatureConfigName
        let enabled: FeatureConfigStatus

        var id: String {
            featureConfigName.rawValue
        }
    }

    @Published var items: [Item] = []
    private let featureConfigRepository: any LegacyFeatureRepositoryInterface
    private let context: NSManagedObjectContext

    init(
        featureConfigRepository: any LegacyFeatureRepositoryInterface,
        context: NSManagedObjectContext
    ) {
        self.featureConfigRepository = featureConfigRepository
        self.context = context
    }

    func fetchFeatureConfigs() async {
        let mls = await featureConfigRepository.fetchMLS()
        let allowedGlobalOperations = await featureConfigRepository.fetchAllowedGlobalOperations()

        await context.perform { [weak self] in
            guard let self else { return }

            let conferenceCalling = featureConfigRepository.fetchConferenceCalling()
            let e2EI = featureConfigRepository.fetchE2EI()
            let appLock = featureConfigRepository.fetchAppLock()
            let channels = featureConfigRepository.fetchChannels()
            let classifiedDomains = featureConfigRepository.fetchClassifiedDomains()
            let consumableNotifications = featureConfigRepository.fetchConsumableNotifications()
            let conversationGuestLinks = featureConfigRepository.fetchConversationGuestLinks()
            let digitalSignature = featureConfigRepository.fetchDigitalSignature()
            let fileSharing = featureConfigRepository.fetchFileSharing()
            let selfDeletingMessages = featureConfigRepository.fetchSelfDeletingMessages()

            items = [
                .init(featureConfigName: .mls, enabled: FeatureConfigStatus(status: mls.status)),
                .init(
                    featureConfigName: .conferenceCalling,
                    enabled: FeatureConfigStatus(status: conferenceCalling.status)
                ),
                .init(featureConfigName: .e2EI, enabled: FeatureConfigStatus(status: e2EI.status)),
                .init(
                    featureConfigName: .allowedGlobalOperations,
                    enabled: FeatureConfigStatus(status: allowedGlobalOperations.status)
                ),
                .init(featureConfigName: .appLock, enabled: FeatureConfigStatus(status: appLock.status)),
                .init(featureConfigName: .channels, enabled: FeatureConfigStatus(status: channels.status)),
                .init(
                    featureConfigName: .classifiedDomains,
                    enabled: FeatureConfigStatus(status: classifiedDomains.status)
                ),
                .init(
                    featureConfigName: .consumableNotifications,
                    enabled: FeatureConfigStatus(status: consumableNotifications.status)
                ),
                .init(
                    featureConfigName: .conversationGuestLinks,
                    enabled: FeatureConfigStatus(status: conversationGuestLinks.status)
                ),
                .init(
                    featureConfigName: .digitalSignature,
                    enabled: FeatureConfigStatus(status: digitalSignature.status)
                ),
                .init(featureConfigName: .fileSharing, enabled: FeatureConfigStatus(status: fileSharing.status)),
                .init(
                    featureConfigName: .selfDeletingMessages,
                    enabled: FeatureConfigStatus(status: selfDeletingMessages.status)
                )
            ]
        }
    }
}
