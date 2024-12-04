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

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    var resourcePath: String {
        "\(pathPrefix)/feature-configs/"
    }

    // MARK: - Get all feature configs

    func getFeatureConfigs() async throws -> [FeatureConfig] {
        let components = URLComponents(string: resourcePath)

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw FeatureConfigsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: FeatureConfigsResponseAPIV0.self)
            .failure(code: .forbidden, label: "operation-denied", error: FeatureConfigsAPIError.insufficientPermissions)
            .failure(code: .forbidden, label: "no-team-member", error: FeatureConfigsAPIError.userIsNotTeamMember)
            .failure(code: .notFound, label: "no-team", error: FeatureConfigsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
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

    func toAPIModel() -> [FeatureConfig] {
        var featureConfigs: [FeatureConfig] = []

        let appLockConfig = appLock.toAPIModel()
        featureConfigs.append(.appLock(appLockConfig))

        let classifiedDomainsConfig = classifiedDomains.toAPIModel()
        featureConfigs.append(.classifiedDomains(classifiedDomainsConfig))

        let conferenceCallingConfig = ConferenceCallingFeatureConfig(
            status: conferenceCalling.status,
            useSFTForOneToOneCalls: false
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

        let selfDeletingMessagesConfig = selfDeletingMessages.toAPIModel()
        featureConfigs.append(.selfDeletingMessages(selfDeletingMessagesConfig))

        return featureConfigs
    }

}

extension FeatureWithConfig<FeatureConfigResponse.AppLockV0>: ToAPIModelConvertible {

    func toAPIModel() -> AppLockFeatureConfig {
        AppLockFeatureConfig(
            status: status,
            isMandatory: config.enforceAppLock,
            inactivityTimeoutInSeconds: config.inactivityTimeoutSecs
        )
    }

}

extension FeatureWithConfig<FeatureConfigResponse.ClassifiedDomainsV0> {

    func toAPIModel() -> ClassifiedDomainsFeatureConfig {
        ClassifiedDomainsFeatureConfig(
            status: status,
            domains: config.domains
        )
    }

}

extension FeatureWithConfig<FeatureConfigResponse.SelfDeletingMessagesV0> {

    func toAPIModel() -> SelfDeletingMessagesFeatureConfig {
        SelfDeletingMessagesFeatureConfig(
            status: status,
            enforcedTimeoutSeconds: config.enforcedTimeoutSeconds
        )
    }

}
