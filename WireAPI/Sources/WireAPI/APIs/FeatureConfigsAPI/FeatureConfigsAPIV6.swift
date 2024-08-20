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

    override func getFeatureConfigs() async throws -> [FeatureConfig] {
        let request = HTTPRequest(
            path: "\(pathPrefix)/feature-configs",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: FeatureConfigsResponseAPIV6.self)
            .failure(code: .forbidden, label: "operation-denied", error: FeatureConfigsAPIError.insufficientPermissions)
            .failure(code: .forbidden, label: "no-team-member", error: FeatureConfigsAPIError.userIsNotTeamMember)
            .failure(code: .notFound, label: "no-team", error: FeatureConfigsAPIError.teamNotFound)
            .parse(response)
    }

}

struct FeatureConfigsResponseAPIV6: Decodable, ToAPIModelConvertible {

    let appLock: FeatureWithConfig<FeatureConfigResponse.AppLockV0>
    let classifiedDomains: FeatureWithConfig<FeatureConfigResponse.ClassifiedDomainsV0>
    let conferenceCalling: FeatureWithoutConfig
    let conversationGuestLinks: FeatureWithoutConfig
    let digitalSignatures: FeatureWithoutConfig
    let fileSharing: FeatureWithoutConfig
    let selfDeletingMessages: FeatureWithConfig<FeatureConfigResponse.SelfDeletingMessagesV0>
    let mls: FeatureWithConfig<FeatureConfigResponse.MLSV4>?
    let mlsMigration: FeatureWithConfig<FeatureConfigResponse.MLSMigrationV6>?
    let mlsE2EId: FeatureWithConfig<FeatureConfigResponse.EndToEndIdentityV6>?

    func toAPIModel() -> [FeatureConfig] {
        var featureConfigs: [FeatureConfig] = []

        let appLockConfig = AppLockFeatureConfig(
            status: appLock.status,
            isMandatory: appLock.config.enforceAppLock,
            inactivityTimeoutInSeconds: appLock.config.inactivityTimeoutSecs
        )

        featureConfigs.append(.appLock(appLockConfig))

        let classifiedDomainsConfig = ClassifiedDomainsFeatureConfig(
            status: classifiedDomains.status,
            domains: classifiedDomains.config.domains
        )

        featureConfigs.append(.classifiedDomains(classifiedDomainsConfig))

        let conferenceCallingConfig = ConferenceCallingFeatureConfig(
            status: conferenceCalling.status
        )

        featureConfigs.append(.conferenceCalling(conferenceCallingConfig))

        let conversationGuestLinksConfig = ConversationGuestLinksFeatureConfig(
            status: conversationGuestLinks.status
        )

        featureConfigs.append(.conversationGuestLinks(conversationGuestLinksConfig))

        let digitalSignaturesConfig = DigitalSignatureFeatureConfig(
            status: digitalSignatures.status
        )

        featureConfigs.append(.digitalSignature(digitalSignaturesConfig))

        let fileSharingConfig = FileSharingFeatureConfig(
            status: fileSharing.status
        )

        featureConfigs.append(.fileSharing(fileSharingConfig))

        let selfDeletingMessagesConfig = SelfDeletingMessagesFeatureConfig(
            status: selfDeletingMessages.status,
            enforcedTimeoutSeconds: selfDeletingMessages.config.enforcedTimeoutSeconds
        )

        featureConfigs.append(.selfDeletingMessages(selfDeletingMessagesConfig))

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
                verificationExpiration: mlsE2EId.config.verificationExpiration,
                crlProxy: mlsE2EId.config.crlProxy,
                useProxyOnMobile: mlsE2EId.config.useProxyOnMobile
            )

            featureConfigs.append(.endToEndIdentity(mlsE2EIdConfig))
        }

        return featureConfigs
    }

}

extension FeatureConfigResponse {

    struct MLSMigrationV6: Decodable {
        let startTime: UTCTime?
        let finaliseRegardlessAfter: UTCTime?
    }

    struct EndToEndIdentityV6: Decodable {

        let acmeDiscoveryUrl: String?
        let verificationExpiration: UInt
        let crlProxy: String? /// Starting api v6
        let useProxyOnMobile: Bool? /// Starting api v6

    }

}
