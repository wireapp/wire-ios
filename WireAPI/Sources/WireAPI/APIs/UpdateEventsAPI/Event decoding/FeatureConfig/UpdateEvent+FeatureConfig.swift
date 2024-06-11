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

extension UpdateEvent {
    init(
        eventType: FeatureConfigEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: FeatureConfigEventCodingKeys.self)

        switch eventType {
        case .update:
            let featureName = try container.decode(
                String.self,
                forKey: .name
            )

            switch featureName {
            case "appLock":
                let config = try AppLockFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .appLock(config))
                self = .featureConfig(.update(event))

            case "classifiedDomains":
                let config = try ClassifiedDomainsFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .classifiedDomains(config))
                self = .featureConfig(.update(event))

            case "conferenceCalling":
                let config = try ConferenceCallingFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .conferenceCalling(config))
                self = .featureConfig(.update(event))

            case "conversationGuestLinks":
                let config = try ConversationGuestLinksFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .conversationGuestLinks(config))
                self = .featureConfig(.update(event))

            case "digitalSignature":
                let config = try DigitalSignatureFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .digitalSignature(config))
                self = .featureConfig(.update(event))

            case "e2ei":
                let config = try EndToEndIdentityFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .endToEndIdentity(config))
                self = .featureConfig(.update(event))

            case "fileSharing":
                let config = try FileSharingFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .fileSharing(config))
                self = .featureConfig(.update(event))

            case "mls":
                let config = try MLSFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .mls(config))
                self = .featureConfig(.update(event))

            case "mlsMigration":
                let config = try MLSMigrationFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .mlsMigration(config))
                self = .featureConfig(.update(event))

            case "selfDeletingMessages":
                let config = try SelfDeletingMessagesFeatureConfigDecoder().decode(from: container)
                let event = FeatureConfigUpdateEvent(featureConfig: .selfDeletingMessages(config))
                self = .featureConfig(.update(event))

            default:
                let event = FeatureConfigUpdateEvent(featureConfig: .unknown(featureName: featureName))
                self = .featureConfig(.update(event))
            }
        }
    }
}
