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
import WireAPI

struct StorableFeatureConfigUpdateEvent: Equatable, Codable, Sendable {

    private let featureConfig: StorableFeatureConfig

    init(_ value: WireAPI.FeatureConfigUpdateEvent) {
        self.featureConfig = switch value.featureConfig {
        case let .appLock(config):
                .appLock(
                    StorableAppLockFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        isMandatory: config.isMandatory,
                        inactivityTimeoutInSeconds: config.inactivityTimeoutInSeconds
                    )
                )
        case let .classifiedDomains(config):
                .classifiedDomains(
                    StorableClassifiedDomainsFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        domains: Array(config.domains)
                    )
                )
        case let .conferenceCalling(config):
                .conferenceCalling(
                    StorableConferenceCallingFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        useSFTForOneToOneCalls: config.useSFTForOneToOneCalls
                    )
                )
        case let .conversationGuestLinks(config):
                .conversationGuestLinks(
                    StorableBasicFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status)
                    )
                )
        case let .digitalSignature(config):
                .digitalSignature(
                    StorableBasicFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status)
                    )
                )
        case let .endToEndIdentity(config):
                .endToEndIdentity(
                    StorableEndToEndIdentityFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        acmeDiscoveryURL: config.acmeDiscoveryURL,
                        verificationExpiration: config.verificationExpiration,
                        crlProxy: config.crlProxy,
                        useProxyOnMobile: config.useProxyOnMobile
                    )
                )
        case let .fileSharing(config):
                .fileSharing(
                    StorableBasicFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status)
                    )
                )
        case let .mls(config):
                .mls(
                    StorableMLSFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        protocolToggleUsers: Array(config.protocolToggleUsers),
                        defaultProtocol: StorableMessageProtocol(config.defaultProtocol),
                        allowedCipherSuites: config.allowedCipherSuites.map { StorableMLSCipherSuite($0) },
                        defaultCipherSuite: StorableMLSCipherSuite(config.defaultCipherSuite),
                        supportedProtocols: config.supportedProtocols.map { StorableMessageProtocol($0) }
                    )
                )
        case let .mlsMigration(config):
            // FIXME: There is a compiler crash :(
            fatalError()
//                .mlsMigration(
//                    StorableMLSMigrationFeatureConfig(
//                        status: StorableFeatureConfigStatus(config.status),
//                        startTime: config.startTime,
//                        finaliseRegardlessAfter: config.finaliseRegardlessAfter
//                    )
//                )
        case let .selfDeletingMessages(config):
                .selfDeletingMessages(
                    StorableSelfDeletingMessagesFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        enforcedTimeoutSeconds: config.enforcedTimeoutSeconds
                    )
                )
        case let .channels(config):
                .channels(
                    StorableChannelsFeatureConfig(
                        status: StorableFeatureConfigStatus(config.status),
                        allowedToCreateChannels: StorableChannelsFeatureConfig.Permission(config.allowedToCreateChannels),
                        allowedToOpenChannels: StorableChannelsFeatureConfig.Permission(config.allowedToOpenChannels)
                    )
                )
        case let .unknown(featureName):
            .unknown(featureName: featureName)
        }
    }

    func toAPIModel() -> WireAPI.FeatureConfigUpdateEvent {
        let config: WireAPI.FeatureConfig = switch featureConfig {
        case let .appLock(config):
            .appLock(
                .init(
                    status: config.status.toAPIModel(),
                    isMandatory: config.isMandatory,
                    inactivityTimeoutInSeconds: config.inactivityTimeoutInSeconds
                )
            )
        case let .classifiedDomains(config):
            .classifiedDomains(
                .init(
                    status: config.status.toAPIModel(),
                    domains: config.domains.toSet()
                )
            )
        case let .conferenceCalling(config):
            .conferenceCalling(
                .init(
                    status: config.status.toAPIModel(),
                    useSFTForOneToOneCalls: config.useSFTForOneToOneCalls
                )
            )
        case let .conversationGuestLinks(config):
            .conversationGuestLinks(
                .init(
                    status: config.status.toAPIModel()
                )
            )
        case let .digitalSignature(config):
            .digitalSignature(
                .init(
                    status: config.status.toAPIModel()
                )
            )
        case let .endToEndIdentity(config):
            .endToEndIdentity(
                .init(
                    status: config.status.toAPIModel(),
                    acmeDiscoveryURL: config.acmeDiscoveryURL,
                    verificationExpiration: config.verificationExpiration,
                    crlProxy: config.crlProxy,
                    useProxyOnMobile: config.useProxyOnMobile
                )
            )
        case let .fileSharing(config):
            .fileSharing(
                .init(
                    status: config.status.toAPIModel()
                )
            )
        case let .mls(config):
            .mls(
                .init(
                    status: config.status.toAPIModel(),
                    protocolToggleUsers: config.protocolToggleUsers.toSet(),
                    defaultProtocol: config.defaultProtocol.toAPIModel(),
                    allowedCipherSuites: config.allowedCipherSuites.map { $0.toAPIModel() },
                    defaultCipherSuite: config.defaultCipherSuite.toAPIModel(),
                    supportedProtocols: config.supportedProtocols.map { $0.toAPIModel() }.toSet()
                )
            )
        case let .mlsMigration(config):
            // FIXME: Implement
            fatalError()
        case let .selfDeletingMessages(config):
                .selfDeletingMessages(
                    .init(
                        status: config.status.toAPIModel(),
                        enforcedTimeoutSeconds: config.enforcedTimeoutSeconds
                    )
                )
        case let .channels(config):
                .channels(
                    ChannelsFeatureConfig(
                        status: config.status.toAPIModel(),
                        allowedToCreateChannels: config.allowedToCreateChannels.toAPIModel(),
                        allowedToOpenChannels: config.allowedToOpenChannels.toAPIModel()
                    )
                )
        case let .unknown(featureName):
            .unknown(featureName: featureName)
        }

        return .init(featureConfig: config)
    }

}

// MARK: Private Models

private enum StorableFeatureConfig: Equatable, Codable, Sendable {

    case appLock(StorableAppLockFeatureConfig)
    case classifiedDomains(StorableClassifiedDomainsFeatureConfig)
    case conferenceCalling(StorableConferenceCallingFeatureConfig)
    case conversationGuestLinks(StorableBasicFeatureConfig)
    case digitalSignature(StorableBasicFeatureConfig)
    case endToEndIdentity(StorableEndToEndIdentityFeatureConfig)
    case fileSharing(StorableBasicFeatureConfig)
    case mls(StorableMLSFeatureConfig)
    case mlsMigration(StorableMLSMigrationFeatureConfig)
    case selfDeletingMessages(StorableSelfDeletingMessagesFeatureConfig)
    case channels(StorableChannelsFeatureConfig)
    case unknown(featureName: String)

}

// MARK: Shared

private enum StorableFeatureConfigStatus: String, Codable, Sendable {

    case enabled
    case disabled

    init(_ value: WireAPI.FeatureConfigStatus) {
        switch value {
        case .enabled:
            self = .enabled
        case .disabled:
            self = .disabled
        }
    }

    func toAPIModel() -> WireAPI.FeatureConfigStatus {
        switch self {
        case .enabled:
            return .enabled
        case .disabled:
            return .disabled
        }
    }

}

// MARK: Feature configs

private struct StorableBasicFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus

}

private struct StorableAppLockFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus
    let isMandatory: Bool
    let inactivityTimeoutInSeconds: UInt

}

private struct StorableClassifiedDomainsFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let domains: [String]

}

private struct StorableConferenceCallingFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus
    let useSFTForOneToOneCalls: Bool

}

private struct StorableEndToEndIdentityFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let acmeDiscoveryURL: String?
    let verificationExpiration: UInt
    let crlProxy: String?
    let useProxyOnMobile: Bool

}

private struct StorableMLSFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let protocolToggleUsers: [UUID]
    let defaultProtocol: StorableMessageProtocol
    let allowedCipherSuites: [StorableMLSCipherSuite]
    let defaultCipherSuite: StorableMLSCipherSuite
    let supportedProtocols: [StorableMessageProtocol]

}

private struct StorableMLSMigrationFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
//        let startTime: Date? FIXME: Uncomment
//        let finaliseRegardlessAfter: Date? FIXME: Uncomment

}

private struct StorableSelfDeletingMessagesFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let enforcedTimeoutSeconds: UInt

}

private struct StorableChannelsFeatureConfig: Codable, Equatable, Sendable {

    enum Permission: String, Codable, Sendable {

        case teamMembers
        case everyone
        case admins

        init(_ value: WireAPI.ChannelsPermision) {
            switch value {
            case .teamMembers:
                self = .teamMembers
            case .everyone:
                self = .everyone
            case .admins:
                self = .admins
            }
        }

        func toAPIModel() -> WireAPI.ChannelsPermision {
            switch self {
            case .teamMembers:
                return .teamMembers
            case .everyone:
                return .everyone
            case .admins:
                return .admins
            }
        }

    }

    let status: StorableFeatureConfigStatus
    let allowedToCreateChannels: Permission
    let allowedToOpenChannels: Permission

}
