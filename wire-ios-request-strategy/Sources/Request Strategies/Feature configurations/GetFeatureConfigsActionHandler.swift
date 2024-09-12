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
import WireDataModel

final class GetFeatureConfigsActionHandler: ActionHandler<GetFeatureConfigsAction> {

    // MARK: - Request

    override func request(
        for action: GetFeatureConfigsActionHandler.Action,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        ZMTransportRequest(
            getFromPath: "/feature-configs",
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Response

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: GetFeatureConfigsActionHandler.Action
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard let apiVersion = APIVersion(rawValue: response.apiVersion) else {
                action.fail(with: .invalidResponse)
                return
            }
            guard
                let data = response.rawData,
                !data.isEmpty
            else {
                action.fail(with: .malformedResponse)
                return
            }

            do {
                let repository = FeatureRepository(context: context)

                let processor = FeatureConfigsPayloadProcessor()

                switch apiVersion {
                case .v0, .v1, .v2, .v3, .v4, .v5:
                    try processor.processActionPayload(
                        data: data,
                        repository: repository)
                case .v6:
                    try processor.processActionPayloadAPIV6(
                        data: data,
                        repository: repository)
                }

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

}
