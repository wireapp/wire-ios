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

public struct EmailCredentials {
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }

    let email: String
    let password: String
}

public class UserClientRequestFactory {

    public init() {}

    func deleteClientRequest(
        clientId: String,
        credentials: EmailCredentials?,
        apiVersion: APIVersion) -> ZMTransportRequest {
            let payload: [AnyHashable: Any]

            if let email = credentials?.email,
               let password = credentials?.password {
                payload = [
                    "email": email,
                    "password": password
                ]
            } else {
                payload = [:]
            }

            let request = ZMTransportRequest(
                path: "/clients/\(clientId)",
                method: ZMTransportRequestMethod.delete,
                payload: payload as ZMTransportData,
                apiVersion: apiVersion.rawValue)

            return request
        }

}
