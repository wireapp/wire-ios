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
import WireTransport

public enum LegalHoldActivationError: Error, Equatable {
    case selfUserNotInTeam
    case invalidSelfUser
    case invalidResponse(Int, String?)
    case invalidPassword
    case couldNotEstablishSession
    case invalidState
    case missingAPIVersion
}

extension ZMUserSession {
    /// Sends a request to accept a legal hold request for the specified user.
    /// - parameter request: The request that was accepted by the user.
    /// - parameter password: The password of the user to send in the payload, if it's not a SSO user.
    /// - parameter completionHandler: The block that will be called with the result of the request.
    /// - parameter error: The error that prevented the approval of legal hold.

    public func accept(
        legalHoldRequest: LegalHoldRequest,
        password: String?,
        completionHandler: @escaping (_ error: LegalHoldActivationError?) -> Void
    ) {
        guard let apiVersion = BackendInfo.apiVersion else {
            return completionHandler(.missingAPIVersion)
        }

        // 1) Check the state
        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        guard let teamID = selfUser.team?.remoteIdentifier else {
            return completionHandler(.selfUserNotInTeam)
        }

        guard let userID = selfUser.remoteIdentifier else {
            return completionHandler(.invalidSelfUser)
        }

        Task {
            let selfUser = await syncManagedObjectContext.perform {
                ZMUser.selfUser(in: self.syncManagedObjectContext)
            }

            // 2) Create the potential LH client
            guard let legalHoldClient: UserClient = await selfUser.addLegalHoldClient(from: legalHoldRequest) else {
                return await MainActor.run {
                    completionHandler(.invalidState)
                }
            }

            _ = await self.syncManagedObjectContext.perform {
                self.syncManagedObjectContext.saveOrRollback()
            }

            // 3) Create the request
            var payload: [String: Any] = [:]
            payload["password"] = password

            let path = "/teams/\(teamID.transportString())/legalhold/\(userID.transportString())/approve"
            let request = ZMTransportRequest(
                path: path,
                method: .put,
                payload: payload as NSDictionary,
                apiVersion: apiVersion.rawValue
            )
            let response = await self.transportSession.enqueue(request, queue: self.syncManagedObjectContext)

            if response.httpStatus == 200 {
                _ = await self.syncContext.perform {
                    selfUser.userDidAcceptLegalHoldRequest(legalHoldRequest)
                    self.syncContext.saveOrRollback()
                }
                await MainActor.run {
                    completionHandler(nil)
                }
            } else {
                await legalHoldClient.deleteClientAndEndSession()
                _ = await self.syncContext.perform {
                    self.syncContext.saveOrRollback()
                }

                let errorLabel = response.payload?.asDictionary()?["label"] as? String
                switch errorLabel {
                case "access-denied", "invalid-payload":
                    await MainActor.run {
                        completionHandler(.invalidPassword)
                    }

                default:
                    await MainActor.run {
                        completionHandler(.invalidResponse(response.httpStatus, errorLabel))
                    }
                }
            }
        }
    }
}
