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

class FeatureConfigsAPIV6: FeatureConfigsAPIV5 {

    override var apiVersion: APIVersion {
        .v6
    }

}

struct FeatureConfigsResponseAPIV6: Decodable, ToAPIModelConvertible {
    
    let appLock: FeatureWithConfig<FeatureConfigResponse.AppLockV0>?
    let classifiedDomains: FeatureWithConfig<FeatureConfigResponse.ClassifiedDomainsV0>?
    let conferenceCalling: FeatureWithoutConfig?
    let conversationGuestLinks: FeatureWithoutConfig?
    let digitalSignatures: FeatureWithoutConfig?
    let fileSharing: FeatureWithoutConfig?
    let mls: FeatureWithConfig<FeatureConfigResponse.MLSV4>?
    let selfDeletingMessages: FeatureWithConfig<FeatureConfigResponse.SelfDeletingMessagesV0>?
    let mlsMigration: FeatureWithConfig<FeatureConfigResponse.MLSMigrationV4>?
    let mlsE2EId: FeatureWithConfig<FeatureConfigResponse.EndToEndIdentityV6>?

    func toAPIModel() -> [FeatureConfig] {
        var featureConfigs: [FeatureConfig] = []

        if let appLock {
            let appLockConfig = AppLockFeatureConfig(
                status: appLock.status,
                isMandatory: appLock.config.enforceAppLock,
                inactivityTimeoutInSeconds: appLock.config.inactivityTimeoutSecs
            )

            featureConfigs.append(.appLock(appLockConfig))
        }

        if let classifiedDomains {
            let classifiedDomainsConfig = ClassifiedDomainsFeatureConfig(
                status: classifiedDomains.status,
                domains: classifiedDomains.config.domains
            )

            featureConfigs.append(.classifiedDomains(classifiedDomainsConfig))
        }

        if let conferenceCalling {
            let conferenceCallingConfig = ConferenceCallingFeatureConfig(
                status: conferenceCalling.status
            )

            featureConfigs.append(.conferenceCalling(conferenceCallingConfig))
        }

        if let conversationGuestLinks {
            let conversationGuestLinksConfig = ConversationGuestLinksFeatureConfig(
                status: conversationGuestLinks.status
            )

            featureConfigs.append(.conversationGuestLinks(conversationGuestLinksConfig))
        }

        if let digitalSignatures {
            let digitalSignaturesConfig = DigitalSignatureFeatureConfig(
                status: digitalSignatures.status
            )

            featureConfigs.append(.digitalSignature(digitalSignaturesConfig))
        }

        if let fileSharing {
            let fileSharingConfig = FileSharingFeatureConfig(
                status: fileSharing.status
            )

            featureConfigs.append(.fileSharing(fileSharingConfig))
        }

        if let mls {
            let mlsConfig = MLSFeatureConfig(
                status: mls.status,
                protocolToggleUsers: mls.config.protocolToggleUsers,
                defaultProtocol: mls.config.defaultProtocol,
                allowedCipherSuites: mls.config.allowedCipherSuites,
                defaultCipherSuite: mls.config.defaultCipherSuite,
                supportedProtocols: mls.config.supportedProtocols
            )

            featureConfigs.append(.mls(mlsConfig))
        }

        if let selfDeletingMessages {
            let selfDeletingMessagesConfig = SelfDeletingMessagesFeatureConfig(
                status: selfDeletingMessages.status,
                enforcedTimeoutSeconds: selfDeletingMessages.config.enforcedTimeoutSeconds
            )

            featureConfigs.append(.selfDeletingMessages(selfDeletingMessagesConfig))
        }

        if let mlsMigration {
            let mlsMigrationConfig = MLSMigrationFeatureConfig(
                status: mlsMigration.status,
                startTime: mlsMigration.config.startTime?.date,
                finaliseRegardlessAfter: mlsMigration.config.finaliseRegardlessAfter?.date

            )

            featureConfigs.append(.mlsMigration(mlsMigrationConfig))
        }

        if let mlsE2EId {
            let mlsE2EIdConfig = EndToEndIdentityFeatureConfig(
                status: mlsE2EId.status,
                acmeDiscoveryURL: mlsE2EId.config.acmeDiscoveryUrl,
                verificationExpiration: mlsE2EId.config.verificationExpiration

            )

            featureConfigs.append(.endToEndIdentity(mlsE2EIdConfig))
        }

        return featureConfigs
    }
    
}

extension FeatureConfigResponse {
    
    struct EndToEndIdentityV6: Decodable {
        
        let acmeDiscoveryUrl: String?
        let verificationExpiration: UInt
        let crlProxy: String? /// Starting api v6
        let useProxyOnMobile: Bool? /// Starting api v6
        
    }
    
}
