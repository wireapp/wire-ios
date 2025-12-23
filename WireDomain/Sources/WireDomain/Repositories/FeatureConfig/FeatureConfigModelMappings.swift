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
import WireDataModel
import WireNetwork

extension WireNetwork.MLSFeatureConfig {

    func toDomainModel() -> WireDataModel.Feature.MLS.Config {
        .init(
            protocolToggleUsers: Array(protocolToggleUsers),
            defaultProtocol: defaultProtocol == .mls ? .mls : .proteus,
            allowedCipherSuites: allowedCipherSuites.map {
                $0.toConfigModel()
            },
            defaultCipherSuite: defaultCipherSuite.toConfigModel(),
            supportedProtocols: Set(supportedProtocols.map {
                switch $0 {
                case .proteus:
                    .proteus
                case .mls:
                    .mls
                }
            })
        )
    }

}

extension WireNetwork.EndToEndIdentityFeatureConfig {

    func toDomainModel() -> WireDataModel.Feature.E2EI.Config {
        .init(
            acmeDiscoveryUrl: acmeDiscoveryURL,
            verificationExpiration: verificationExpiration,
            crlProxy: crlProxy,
            useProxyOnMobile: useProxyOnMobile
        )
    }

}

extension WireNetwork.AppLockFeatureConfig {

    func toDomainModel() -> Feature.AppLock.Config {
        .init(
            enforceAppLock: isMandatory,
            inactivityTimeoutSecs: inactivityTimeoutInSeconds
        )
    }
}

extension WireNetwork.ClassifiedDomainsFeatureConfig {

    func toDomainModel() -> Feature.ClassifiedDomains.Config {
        .init(
            domains: Array(domains)
        )
    }

}

extension WireNetwork.ConferenceCallingFeatureConfig {

    func toDomainModel() -> Feature.ConferenceCalling.Config {
        .init(useSFTForOneToOneCalls: useSFTForOneToOneCalls)
    }

}

extension WireNetwork.MLSMigrationFeatureConfig {

    func toDomainModel() -> Feature.MLSMigration.Config {
        .init(
            startTime: startTime,
            finaliseRegardlessAfter: finaliseRegardlessAfter
        )
    }

}

extension WireNetwork.SelfDeletingMessagesFeatureConfig {

    func toDomainModel() -> Feature.SelfDeletingMessages.Config {
        .init(enforcedTimeoutSeconds: enforcedTimeoutSeconds)
    }

}

extension WireNetwork.AllowedGlobalOperationsFeatureConfig {
    func toDomainModel() -> Feature.AllowedGlobalOperations.Config {
        .init(mlsConversationReset: resetMLSConversations)
    }
}

extension WireNetwork.ChannelsFeatureConfig {

    func toDomainModel() -> Feature.Channels.Config {
        .init(
            allowedToCreateChannels: allowedToCreateChannels.toDomainModel(),
            allowedToOpenChannels: allowedToOpenChannels.toDomainModel()
        )
    }

}

extension WireNetwork.ChannelsPermision {
    func toDomainModel() -> Feature.Channels.Config.ChannelsPermision {
        switch self {
        case .admins:
            .admins
        case .everyone:
            .everyone
        case .teamMembers:
            .teamMembers
        }
    }
}

extension WireNetwork.CellsInternalFeatureConfig {
    func toDomainModel() -> Feature.CellsInternal.Config {
        Feature.CellsInternal.Config(
            backend: .init(url: backendURL)
        )
    }
}
