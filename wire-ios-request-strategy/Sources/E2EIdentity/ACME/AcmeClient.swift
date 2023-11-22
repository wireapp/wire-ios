//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCoreCrypto

public protocol AcmeClientInterface {
    func getACMEDirectory() async throws -> Data
}

/// This class provides ACME(Automatic Certificate Management Environment) server methods for enrolling an E2EI certificate.
public class AcmeClient: NSObject, AcmeClientInterface {

    // MARK: - Properties

    private let httpClient: HttpClient

    // MARK: - Life cycle

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func getACMEDirectory() async throws -> Data {

        guard let domain = BackendInfo.domain else {
            throw NetworkError.invalidRequestURL
        }

        let path = "https://acme.\(domain)/acme/defaultteams/directory"

        let request = ZMTransportRequest(getFromPath: path, apiVersion: 0)
        let result = try await httpClient.send(request)

        guard let data = result.rawData else {
            throw NetworkError.invalidResponse
        }

        return data

    }

}
