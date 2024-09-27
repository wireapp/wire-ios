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
import WireDataModel

class SyncUsersActionHandler: ActionHandler<SyncUsersAction> {
    // MARK: Lifecycle

    required init(
        context: NSManagedObjectContext,
        payloadProcessor: UserProfilePayloadProcessing? = nil
    ) {
        self.payloadProcessor = payloadProcessor ?? UserProfilePayloadProcessor()
        super.init(context: context)
    }

    // MARK: Internal

    // MARK: - Request

    struct RequestPayload: Codable, Equatable {
        let qualified_ids: [QualifiedID]
    }

    override func request(
        for action: SyncUsersAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            action.fail(with: .endpointUnavailable)
            return nil

        case .v4, .v5, .v6:
            guard
                let payloadData = RequestPayload(qualified_ids: action.qualifiedIDs).payloadString()
            else {
                action.fail(with: .failedToEncodeRequestPayload)
                return nil
            }

            return ZMTransportRequest(
                path: "/list-users",
                method: .post,
                payload: payloadData as ZMTransportData,
                apiVersion: apiVersion.rawValue
            )
        }
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: SyncUsersAction
    ) {
        var action = action

        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
            action.fail(with: .endpointUnavailable)
            return
        }

        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            action.fail(with: .endpointUnavailable)
            return

        case .v4, .v5, .v6:
            switch response.httpStatus {
            case 200:
                guard let rawData = response.rawData,
                      let payload = Payload.UserProfilesV4(rawData)
                else {
                    action.fail(with: .invalidResponsePayload)
                    return
                }

                payloadProcessor.updateUserProfiles(
                    from: payload.found,
                    in: context
                )

                if let failedIdentifiers = payload.failed {
                    markUserProfilesAsUnavailable(Set(failedIdentifiers))
                }

                action.succeed()

            default:
                let errorInfo = response.errorInfo
                action.fail(with: .unknownError(
                    code: errorInfo.status,
                    label: errorInfo.label,
                    message: errorInfo.message
                ))
            }
        }
    }

    // MARK: Private

    private let payloadProcessor: UserProfilePayloadProcessing

    private func markUserProfilesAsUnavailable(_ users: Set<QualifiedID>) {
        context.performAndWait {
            for qualifiedID in users {
                let user = ZMUser.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
                user?.isPendingMetadataRefresh = true
                user?.needsToBeUpdatedFromBackend = false
            }
        }
    }
}
