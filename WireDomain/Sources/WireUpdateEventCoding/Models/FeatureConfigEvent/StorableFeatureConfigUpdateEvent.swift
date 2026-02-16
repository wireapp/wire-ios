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
import WireNetwork

struct StorableFeatureConfigUpdateEvent: Equatable, Codable, Sendable {

    private let featureConfig: StorableFeatureConfig

    init(_ value: WireNetwork.FeatureConfigUpdateEvent) {
        self.featureConfig = switch value.featureConfig {
        case let .appLock(config):
            .appLock(
                StorableAppLockFeatureConfig(
                    status: StorableFeatureConfigStatus(config.status),
                    isMandatory: config.isMandatory,
                    inactivityTimeoutInSeconds: config.inactivityTimeoutInSeconds
                )
            )
        case let .apps(config):
            .apps(
                StorableBasicFeatureConfig(
                    status: StorableFeatureConfigStatus(
                        config.status
                    )
                )
            )
        case let .assetAuditLog(config):
            .assetAuditLog(
                StorableBasicFeatureConfig(
                    status: StorableFeatureConfigStatus(config.status)
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
            .mlsMigration(
                StorableMLSMigrationFeatureConfig(
                    status: StorableFeatureConfigStatus(config.status),
                    startTime: config.startTime,
                    finaliseRegardlessAfter: config.finaliseRegardlessAfter
                )
            )
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
                    allowedToCreateChannels: StorableChannelsFeatureConfig
                        .Permission(config.allowedToCreateChannels),
                    allowedToOpenChannels: StorableChannelsFeatureConfig.Permission(config.allowedToOpenChannels)
                )
            )
        case let .allowedGlobalOperations(config):
            .allowedGlobalOperations(
                StorableAllowedGlobalOperationsFeatureConfig(
                    status: StorableFeatureConfigStatus(config.status),
                    resetMLSConversations: config.resetMLSConversations
                )
            )
        case let .consumableNotifications(config):
            .consumableNotifications(
                StorableBasicFeatureConfig(
                    status: StorableFeatureConfigStatus(
                        config.status
                    )
                )
            )
        case let .cells(config):
            .cells(
                StorableBasicFeatureConfig(
                    status: StorableFeatureConfigStatus(
                        config.status
                    )
                )
            )
        case let .cellsInternal(config):
            .cellsInternal(
                StorableCellsInternalFeatureConfig(
                    status: StorableFeatureConfigStatus(config.status),
                    backendURL: config.backendURL
                )
            )
        case let .unknown(featureName):
            .unknown(featureName: featureName)
        }
    }

    func toAPIModel() -> WireNetwork.FeatureConfigUpdateEvent {
        let config: WireNetwork.FeatureConfig = switch featureConfig {
        case let .appLock(config):
            .appLock(
                .init(
                    status: config.status.toAPIModel(),
                    isMandatory: config.isMandatory,
                    inactivityTimeoutInSeconds: config.inactivityTimeoutInSeconds
                )
            )
        case let .apps(config):
            .apps(
                .init(status: config.status.toAPIModel())
            )
        case let .assetAuditLog(config):
            .assetAuditLog(
                .init(
                    status: config.status.toAPIModel()
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
            .mlsMigration(
                MLSMigrationFeatureConfig(
                    status: config.status.toAPIModel(),
                    startTime: config.startTime,
                    finaliseRegardlessAfter: config.finaliseRegardlessAfter
                )
            )
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
        case let .allowedGlobalOperations(config):
            .allowedGlobalOperations(
                AllowedGlobalOperationsFeatureConfig(
                    status: config.status.toAPIModel(),
                    resetMLSConversations: config.resetMLSConversations
                )
            )
        case let .consumableNotifications(config):
            .consumableNotifications(
                ConsumableNotificationsFeatureConfig(
                    status: config.status.toAPIModel()
                )
            )
        case let .cells(config):
            .cells(
                .init(status: config.status.toAPIModel())
            )
        case let .cellsInternal(config):
            .cellsInternal(
                .init(
                    status: config.status.toAPIModel(),
                    backendURL: config.backendURL
                )
            )
        case let .unknown(featureName):
            .unknown(featureName: featureName)
        }

        return .init(featureConfig: config)
    }

}

// MARK: Private Models

// NOTE: All the following models should be `private`. However, when doing so the Swift compiler crashes. Hopefully this
// will be fixed in the future. For now, we have to keep them `internal`.

enum StorableFeatureConfig: Equatable, Codable, Sendable {

    case appLock(StorableAppLockFeatureConfig)
    case apps(StorableBasicFeatureConfig)
    case assetAuditLog(StorableBasicFeatureConfig)
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
    case allowedGlobalOperations(StorableAllowedGlobalOperationsFeatureConfig)
    case consumableNotifications(StorableBasicFeatureConfig)
    case cells(StorableBasicFeatureConfig)
    case cellsInternal(StorableCellsInternalFeatureConfig)
    case unknown(featureName: String)

}

// MARK: Shared

enum StorableFeatureConfigStatus: String, Codable, Sendable {

    case enabled
    case disabled

    init(_ value: WireNetwork.FeatureConfigStatus) {
        switch value {
        case .enabled:
            self = .enabled
        case .disabled:
            self = .disabled
        }
    }

    func toAPIModel() -> WireNetwork.FeatureConfigStatus {
        switch self {
        case .enabled:
            .enabled
        case .disabled:
            .disabled
        }
    }

}

// MARK: Feature configs

struct StorableBasicFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus

}

struct StorableAppLockFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus
    let isMandatory: Bool
    let inactivityTimeoutInSeconds: UInt

}

struct StorableClassifiedDomainsFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let domains: [String]

}

struct StorableConferenceCallingFeatureConfig: Codable, Equatable, Sendable {

    let status: StorableFeatureConfigStatus
    let useSFTForOneToOneCalls: Bool

}

struct StorableEndToEndIdentityFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let acmeDiscoveryURL: String?
    let verificationExpiration: UInt
    let crlProxy: String?
    let useProxyOnMobile: Bool

}

struct StorableMLSFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let protocolToggleUsers: [UUID]
    let defaultProtocol: StorableMessageProtocol
    let allowedCipherSuites: [StorableMLSCipherSuite]
    let defaultCipherSuite: StorableMLSCipherSuite
    let supportedProtocols: [StorableMessageProtocol]

}

struct StorableMLSMigrationFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let startTime: Date?
    let finaliseRegardlessAfter: Date?

}

struct StorableSelfDeletingMessagesFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let enforcedTimeoutSeconds: UInt

}

struct StorableAllowedGlobalOperationsFeatureConfig: Equatable, Codable, Sendable {

    let status: StorableFeatureConfigStatus
    let resetMLSConversations: Bool
}

struct StorableChannelsFeatureConfig: Codable, Equatable, Sendable {

    enum Permission: String, Codable, Sendable {

        case teamMembers
        case everyone
        case admins

        init(_ value: WireNetwork.ChannelsPermission) {
            switch value {
            case .teamMembers:
                self = .teamMembers
            case .everyone:
                self = .everyone
            case .admins:
                self = .admins
            }
        }

        func toAPIModel() -> WireNetwork.ChannelsPermission {
            switch self {
            case .teamMembers:
                .teamMembers
            case .everyone:
                .everyone
            case .admins:
                .admins
            }
        }

    }

    let status: StorableFeatureConfigStatus
    let allowedToCreateChannels: Permission
    let allowedToOpenChannels: Permission

}

struct StorableCellsInternalFeatureConfig: Codable, Equatable, Sendable {
    let status: StorableFeatureConfigStatus
    let backendURL: URL
}
