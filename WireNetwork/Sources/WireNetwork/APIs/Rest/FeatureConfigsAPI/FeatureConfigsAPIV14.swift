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

final class FeatureConfigsAPIV14: FeatureConfigsAPIV13 {

    override var apiVersion: APIVersion { .v14 }

    override func getFeatureConfigs() async throws -> [FeatureConfig] {
        let request = try URLRequestBuilder(path: resourcePath)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: FeatureConfigsResponseAPIV12.self)
            .failure(code: .forbidden, label: "operation-denied", error: FeatureConfigsAPIError.insufficientPermissions)
            .failure(code: .forbidden, label: "no-team-member", error: FeatureConfigsAPIError.userIsNotTeamMember)
            .failure(code: .notFound, label: "no-team", error: FeatureConfigsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

struct FeatureConfigsResponseAPIV14: Decodable, ToAPIModelConvertible {

    let appLock: FeatureWithConfig<FeatureConfigResponse.AppLockV0>
    let apps: FeatureWithoutConfig
    let classifiedDomains: FeatureWithConfig<FeatureConfigResponse.ClassifiedDomainsV0>
    let conferenceCalling: FeatureWithConfig<FeatureConfigResponse.ConferenceCallingV6>
    let conversationGuestLinks: FeatureWithoutConfig
    let digitalSignatures: FeatureWithoutConfig
    let fileSharing: FeatureWithoutConfig
    let selfDeletingMessages: FeatureWithConfig<FeatureConfigResponse.SelfDeletingMessagesV0>
    let mls: FeatureWithConfig<FeatureConfigResponse.MLSV4>
    let mlsMigration: FeatureWithConfig<FeatureConfigResponse.MLSMigrationV6>
    let mlsE2EId: FeatureWithConfig<FeatureConfigResponse.EndToEndIdentityV6>
    let channels: FeatureWithConfig<FeatureConfigResponse.ChannelsV8>
    let cells: FeatureWithoutConfig
    let allowedGlobalOperations: FeatureWithConfig<FeatureConfigResponse.AllowedGlobalOperationsV10>
    let consumableNotifications: FeatureWithoutConfig
    let assetAuditLog: FeatureWithoutConfig
    
    // added in v14
    let cellsInternal: FeatureWithConfig<FeatureConfigResponse.CellsInternalV14>

    func toAPIModel() -> [FeatureConfig] {
        var featureConfigs: [FeatureConfig] = []

        let appLockConfig = appLock.toAPIModel()
        featureConfigs.append(.appLock(appLockConfig))

        let appsFeatureConfig = AppsFeatureConfig(status: apps.status.toAPIModel())
        featureConfigs.append(.apps(appsFeatureConfig))

        let classifiedDomainsConfig = classifiedDomains.toAPIModel()
        featureConfigs.append(.classifiedDomains(classifiedDomainsConfig))

        let conferenceCallingConfig = ConferenceCallingFeatureConfig(
            status: conferenceCalling.status.toAPIModel(),
            useSFTForOneToOneCalls: conferenceCalling.config.useSFTForOneToOneCalls
        )

        featureConfigs.append(.conferenceCalling(conferenceCallingConfig))

        let conversationGuestLinksConfig = ConversationGuestLinksFeatureConfig(
            status: conversationGuestLinks.status
                .toAPIModel()
        )
        featureConfigs.append(.conversationGuestLinks(conversationGuestLinksConfig))

        let digitalSignaturesConfig = DigitalSignatureFeatureConfig(status: digitalSignatures.status.toAPIModel())
        featureConfigs.append(.digitalSignature(digitalSignaturesConfig))

        let fileSharingConfig = FileSharingFeatureConfig(status: fileSharing.status.toAPIModel())
        featureConfigs.append(.fileSharing(fileSharingConfig))

        let selfDeletingMessagesConfig = selfDeletingMessages.toAPIModel()
        featureConfigs.append(.selfDeletingMessages(selfDeletingMessagesConfig))

        let mlsConfig = MLSFeatureConfig(
            status: mls.status.toAPIModel(),
            protocolToggleUsers: mls.config.protocolToggleUsers,
            defaultProtocol: mls.config.defaultProtocol.toAPIModel(),
            allowedCipherSuites: mls.config.allowedCipherSuites.map { $0.toAPIModel() },
            defaultCipherSuite: mls.config.defaultCipherSuite.toAPIModel(),
            supportedProtocols: Set(mls.config.supportedProtocols.map { $0.toAPIModel() })
        )

        featureConfigs.append(.mls(mlsConfig))

        let mlsMigrationConfig = MLSMigrationFeatureConfig(
            status: mlsMigration.status.toAPIModel(),
            startTime: mlsMigration.config.startTime?.date,
            finaliseRegardlessAfter: mlsMigration.config.finaliseRegardlessAfter?.date
        )

        featureConfigs.append(.mlsMigration(mlsMigrationConfig))

        let mlsE2EIdConfig = EndToEndIdentityFeatureConfig(
            status: mlsE2EId.status.toAPIModel(),
            acmeDiscoveryURL: mlsE2EId.config.acmeDiscoveryUrl,
            verificationExpiration: mlsE2EId.config.verificationExpiration,
            crlProxy: mlsE2EId.config.crlProxy,
            useProxyOnMobile: mlsE2EId.config.useProxyOnMobile
        )

        featureConfigs.append(.endToEndIdentity(mlsE2EIdConfig))

        let channelsConfig = ChannelsFeatureConfig(
            status: channels.status.toAPIModel(),
            allowedToCreateChannels: channels.config.allowedToCreateChannels.toAPIModel(),
            allowedToOpenChannels: channels.config.allowedToOpenChannels.toAPIModel()
        )
        featureConfigs.append(.channels(channelsConfig))

        let allowedGlobalOperations = AllowedGlobalOperationsFeatureConfig(
            status: allowedGlobalOperations.status.toAPIModel(),
            resetMLSConversations: allowedGlobalOperations.config.mlsConversationReset
        )
        featureConfigs.append(.allowedGlobalOperations(allowedGlobalOperations))

        let consumableNotifications = ConsumableNotificationsFeatureConfig(
            status: consumableNotifications.status
                .toAPIModel()
        )
        featureConfigs.append(.consumableNotifications(consumableNotifications))

        featureConfigs.append(.assetAuditLog(AssetAuditLogFeatureConfig(
            status: assetAuditLog.status.toAPIModel()
        )))

        let cellsFeatureConfig = CellsFeatureConfig(status: cells.status.toAPIModel())
        featureConfigs.append(.cells(cellsFeatureConfig))
        
        // added in v14
        let cellsInternalConfig = CellsInternalFeatureConfig(
            status: cellsInternal.status.toAPIModel(),
            backendURL: cellsInternal.config.backend.url
        )
        featureConfigs.append(.cellsInternal(cellsInternalConfig))

        return featureConfigs
    }

}

extension FeatureConfigResponse {

    struct CellsInternalV14: Decodable {
        let backend: BackendV14
        
        struct BackendV14: Decodable {
            let url: URL
        }
    }

}
