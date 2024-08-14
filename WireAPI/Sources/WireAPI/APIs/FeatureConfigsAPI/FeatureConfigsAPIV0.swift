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

class FeatureConfigsAPIV0: FeatureConfigsAPI, VersionedAPI {

    let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    // MARK: - Get all feature configs

    func getAllFeatureConfigs() async throws -> [FeatureConfig] {
        let request = HTTPRequest(
            path: "\(pathPrefix)/feature-configs",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200, type: FeatureConfigsResponseAPIV0.self)
            .failure(code: 403, label: "operation-denied", error: FeatureConfigsAPIError.insufficientPermissions)
            .failure(code: 403, label: "no-team-member", error: FeatureConfigsAPIError.userIsNotTeamMember)
            .failure(code: 404, label: "no-team", error: FeatureConfigsAPIError.teamNotFound)
            .parse(response)
    }

}

/// A namespace for all feature config responses

enum FeatureConfigResponse {
    
    struct AppLockV0: Decodable {
        
        let enforceAppLock: Bool
        let inactivityTimeoutSecs: UInt
        
    }

    struct ClassifiedDomainsV0: Decodable {
        
        let domains: Set<String>
        
    }

    struct MLSV0: Decodable {
        
        let protocolToggleUsers: Set<UUID>
        let defaultProtocol: SupportedProtocol
        let allowedCipherSuites: [MLSCipherSuite]
        let defaultCipherSuite: MLSCipherSuite
        
    }

    struct SelfDeletingMessagesV0: Decodable {
        
        let enforcedTimeoutSeconds: UInt
        
    }

}

struct FeatureConfigsResponseAPIV0: Decodable, ToAPIModelConvertible {
    
    let appLock: FeatureWithConfig<FeatureConfigResponse.AppLockV0>
    let classifiedDomains: FeatureWithConfig<FeatureConfigResponse.ClassifiedDomainsV0>
    let conferenceCalling: FeatureWithoutConfig
    let conversationGuestLinks: FeatureWithoutConfig
    let digitalSignatures: FeatureWithoutConfig
    let fileSharing: FeatureWithoutConfig
    let selfDeletingMessages: FeatureWithConfig<FeatureConfigResponse.SelfDeletingMessagesV0>
    let mls: FeatureWithConfig<FeatureConfigResponse.MLSV0>?

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
                supportedProtocols: [.proteus] /// Default to Proteus
            )

            featureConfigs.append(.mls(mlsConfig))
        }

        return featureConfigs
    }
    
}
