//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

final class GetFeatureConfigsActionHandler: ActionHandler<GetFeatureConfigsAction> {

    // MARK: - Request

    override func request(
        for action: GetFeatureConfigsActionHandler.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "/feature-configs", apiVersion: apiVersion.rawValue)
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: GetFeatureConfigsActionHandler.Action
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let data = response.rawData,
                !data.isEmpty
            else {
                action.fail(with: .malformedResponse)
                return
            }

            do {
                let payload = try JSONDecoder().decode(ResponsePayload.self, from: data)
                processPayload(payload)
                action.succeed()
            } catch {
                action.fail(with: .failedToDecodeResponse(reason: error.localizedDescription))
            }

        case (403, "operation-denied"):
            action.fail(with: .insufficientPermissions)

        case (403, "no-team-member"):
            action.fail(with: .userIsNotTeamMember)

        case (404, "no-team"):
            action.fail(with: .teamNotFound)

        case let (status, label):
            action.fail(with: .unknown(status: status, label: label ?? ""))
        }
    }

    private func processPayload(_ payload: ResponsePayload) {
        let featureRepository = FeatureRepository(context: context)

        if let appLock = payload.appLock {
            featureRepository.storeAppLock(
                Feature.AppLock(
                    status: appLock.status,
                    config: appLock.config
                )
            )
        }

        if let classifiedDomains = payload.classifiedDomains {
            featureRepository.storeClassifiedDomains(
                Feature.ClassifiedDomains(
                    status: classifiedDomains.status,
                    config: classifiedDomains.config
                )
            )
        }

        if let conferenceCalling = payload.conferenceCalling {
            featureRepository.storeConferenceCalling(
                Feature.ConferenceCalling(
                    status: conferenceCalling.status
                )
            )
        }

        if let conversationGuestLinks = payload.conversationGuestLinks {
            featureRepository.storeConversationGuestLinks(
                Feature.ConversationGuestLinks(
                    status: conversationGuestLinks.status
                )
            )
        }

        if let digitalSignatures = payload.digitalSignatures {
            featureRepository.storeDigitalSignature(
                Feature.DigitalSignature(
                    status: digitalSignatures.status
                )
            )
        }

        if let fileSharing = payload.fileSharing {
            featureRepository.storeFileSharing(
                Feature.FileSharing(
                    status: fileSharing.status
                )
            )
        }

        if let mls = payload.mls {
            featureRepository.storeMLS(
                Feature.MLS(
                    status: mls.status,
                    config: mls.config
                )
            )
        }

        if let selfDeletingMessages = payload.selfDeletingMessages {
            featureRepository.storeSelfDeletingMessages(
                Feature.SelfDeletingMessages(
                    status: selfDeletingMessages.status,
                    config: selfDeletingMessages.config
                )
            )
        }

        if let e2ei = payload.mlsE2EId {
            featureRepository.storeE2EId(
                Feature.E2EId(
                    status: e2ei.status,
                    config: e2ei.config
                )
            )
        }

    }

}

// MARK: - Response Payload

extension GetFeatureConfigsActionHandler {

    struct ResponsePayload: Codable {

        let appLock: FeatureStatusWithConfig<Feature.AppLock.Config>?
        let classifiedDomains: FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>?
        let conferenceCalling: FeatureStatus?
        let conversationGuestLinks: FeatureStatus?
        let digitalSignatures: FeatureStatus?
        let fileSharing: FeatureStatus?
        let mls: FeatureStatusWithConfig<Feature.MLS.Config>?
        let selfDeletingMessages: FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>?
        let mlsE2EId: FeatureStatusWithConfig<Feature.E2EId.Config>?

    }

}
