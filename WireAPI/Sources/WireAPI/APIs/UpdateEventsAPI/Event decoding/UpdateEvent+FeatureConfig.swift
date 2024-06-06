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
                let config = try container.decodeAppLockConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .appLock(config))
                self = .featureConfig(.update(event))

            case "classifiedDomains":
                let config = try container.decodeClassifiedDomainsConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .classifiedDomains(config))
                self = .featureConfig(.update(event))

            case "conferenceCalling":
                let config = try container.decodeConferenceCallingConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .conferenceCalling(config))
                self = .featureConfig(.update(event))

            case "conversationGuestLinks":
                let config = try container.decodeConversationGuestLinksConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .conversationGuestLinks(config))
                self = .featureConfig(.update(event))

            case "digitalSignature":
                let config = try container.decodeDigitalSignatureConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .digitalSignature(config))
                self = .featureConfig(.update(event))

            case "e2ei":
                let config = try container.decodeEndToEndIdentityConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .endToEndIdentity(config))
                self = .featureConfig(.update(event))

            case "fileSharing":
                let config = try container.decodeFileSharingConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .fileSharing(config))
                self = .featureConfig(.update(event))

            case "mls":
                let config = try container.decodeMLSConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .mls(config))
                self = .featureConfig(.update(event))

            case "mlsMigration":
                let config = try container.decodeMLSMigrationConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .mlsMigration(config))
                self = .featureConfig(.update(event))

            case "selfDeletingMessages":
                let config = try container.decodeSelfDeletingMessagesConfig()
                let event = FeatureConfigUpdateEvent(featureConfig: .selfDeletingMessages(config))
                self = .featureConfig(.update(event))

            default:
                let event = FeatureConfigUpdateEvent(featureConfig: .unknown(featureName: featureName))
                self = .featureConfig(.update(event))
            }
        }
    }

}

private enum FeatureConfigEventCodingKeys: String, CodingKey {

    case name
    case payload = "data"

}

private struct FeatureWithoutConfig: Decodable {

    let status: FeatureConfigStatus

}

private struct FeatureWithConfig<Config: Decodable>: Decodable {

    let status: FeatureConfigStatus
    let config: Config

}

// MARK: - App lock update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeAppLockConfig() throws -> AppLockFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<AppLockConfig>.self,
            forKey: .payload
        )

        return AppLockFeatureConfig(
            status: payload.status,
            isMandatory: payload.config.enforceAppLock,
            inactivityTimeoutInSeconds: payload.config.inactivityTimeoutSecs
        )
    }

    private struct AppLockConfig: Decodable {

        let enforceAppLock: Bool
        let inactivityTimeoutSecs: UInt

    }

}

// MARK: - Classified domains update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeClassifiedDomainsConfig() throws -> ClassifiedDomainsFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<ClassifiedDomainsConfig>.self,
            forKey: .payload
        )

        return ClassifiedDomainsFeatureConfig(
            status: payload.status,
            domains: payload.config.domains
        )
    }

    private struct ClassifiedDomainsConfig: Decodable {

        let domains: Set<String>

    }

}

// MARK: - Conference calling update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeConferenceCallingConfig() throws -> ConferenceCallingFeatureConfig {
        let payload = try decode(
            FeatureWithoutConfig.self,
            forKey: .payload
        )

        return ConferenceCallingFeatureConfig(status: payload.status)
    }

}

// MARK: - Conversation guest links update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeConversationGuestLinksConfig() throws -> ConversationGuestLinksFeatureConfig {
        let payload = try decode(
            FeatureWithoutConfig.self,
            forKey: .payload
        )

        return ConversationGuestLinksFeatureConfig(status: payload.status)
    }

}

// MARK: - Digital signature update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeDigitalSignatureConfig() throws -> DigitalSignatureFeatureConfig {
        let payload = try decode(
            FeatureWithoutConfig.self,
            forKey: .payload
        )

        return DigitalSignatureFeatureConfig(status: payload.status)
    }

}

// MARK: - End to end identity update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeEndToEndIdentityConfig() throws -> EndToEndIdentityFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<EndToEndIdentityConfig>.self,
            forKey: .payload
        )

        return EndToEndIdentityFeatureConfig(
            status: payload.status,
            acmeDiscoveryURL: payload.config.acmeDiscoveryUrl,
            verificationExpiration: payload.config.verificationExpiration
        )
    }

    private struct EndToEndIdentityConfig: Decodable {

        let acmeDiscoveryUrl: String?
        let verificationExpiration: UInt

    }

}

// MARK: - File sharing update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeFileSharingConfig() throws -> FileSharingFeatureConfig {
        let payload = try decode(
            FeatureWithoutConfig.self,
            forKey: .payload
        )

        return FileSharingFeatureConfig(status: payload.status)
    }

}

// MARK: - MLS update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeMLSConfig() throws -> MLSFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<MLSConfig>.self,
            forKey: .payload
        )

        return MLSFeatureConfig(
            status: payload.status,
            protocolToggleUsers: payload.config.protocolToggleUsers,
            defaultProtocol: payload.config.defaultProtocol,
            allowedCipherSuites: payload.config.allowedCipherSuites,
            defaultCipherSuite: payload.config.defaultCipherSuite,
            supportedProtocols: payload.config.supportedProtocols
        )
    }

    private struct MLSConfig: Decodable {

        let protocolToggleUsers: Set<UUID>
        let defaultProtocol: MessageProtocol
        let allowedCipherSuites: [MLSCipherSuite]
        let defaultCipherSuite: MLSCipherSuite
        let supportedProtocols: Set<MessageProtocol>

    }

}

// MARK: - MLS migration update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeMLSMigrationConfig() throws -> MLSMigrationFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<MLSMigrationConfig>.self,
            forKey: .payload
        )

        return MLSMigrationFeatureConfig(
            status: payload.status,
            startTime: payload.config.startTime,
            finaliseRegardlessAfter: payload.config.finaliseRegardlessAfter
        )
    }

    private struct MLSMigrationConfig: Decodable {

        let startTime: Date?
        let finaliseRegardlessAfter: Date?

    }

}

// MARK: - SelfDeletingMessagesn update

private extension KeyedDecodingContainer<FeatureConfigEventCodingKeys> {

    func decodeSelfDeletingMessagesConfig() throws -> SelfDeletingMessagesFeatureConfig {
        let payload = try decode(
            FeatureWithConfig<SelfDeletingMessagesConfig>.self,
            forKey: .payload
        )

        return SelfDeletingMessagesFeatureConfig(
            status: payload.status,
            enforcedTimeoutSeconds: payload.config.enforcedTimeoutSeconds
        )
    }

    private struct SelfDeletingMessagesConfig: Decodable {

        let enforcedTimeoutSeconds: UInt

    }

}
