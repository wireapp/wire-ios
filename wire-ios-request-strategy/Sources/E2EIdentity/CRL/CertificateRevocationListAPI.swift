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

// MARK: - CertificateRevocationListAPIProtocol

// sourcery: AutoMockable
public protocol CertificateRevocationListAPIProtocol {
    func getRevocationList(from distributionPoint: URL) async throws -> Data
}

// MARK: - CertificateRevocationListAPI

public class CertificateRevocationListAPI: CertificateRevocationListAPIProtocol {
    private let httpClient: HttpClientCustom

    public init(httpClient: HttpClientCustom = HttpClientE2EI()) {
        self.httpClient = httpClient
    }

    public func getRevocationList(from distributionPoint: URL) async throws -> Data {
        var request = URLRequest(url: distributionPoint)
        request.httpMethod = "GET"
        let (data, response) = try await httpClient.send(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.notAnHTTPResponse
        }

        switch httpResponse.statusCode {
        case 200 ... 299:
            return data
        default:
            throw NetworkError.invalidStatusCode(httpResponse.statusCode)
        }
    }

    enum NetworkError: Error, Equatable {
        case notAnHTTPResponse
        case invalidStatusCode(Int)
    }
}
