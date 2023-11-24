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

public protocol E2eIEnrollmentInterface {

    /// Fetch acme directory for hyperlinks.
    func loadACMEDirectory() async throws -> AcmeDirectory

    /// Get a nonce for creating an account.
    func getACMENonce(endpoint: String) async throws -> String
}

/// This class implements the steps of the E2EI certificate enrollment process.
public final class E2eIEnrollment: E2eIEnrollmentInterface {

    private var acmeClient: AcmeClientInterface
    private var e2eiService: E2eIServiceInterface
    private let logger = WireLogger.e2ei

    public init(acmeClient: AcmeClientInterface, e2eiService: E2eIServiceInterface) {
        self.acmeClient = acmeClient
        self.e2eiService = e2eiService
    }

    public func loadACMEDirectory() async throws -> AcmeDirectory {
        logger.info("load ACME directory")

        do {
            let acmeDirectoryData = try await acmeClient.getACMEDirectory()
            return try await e2eiService.getDirectoryResponse(directoryData: acmeDirectoryData)
        } catch {
            logger.error("failed to load ACME directory: \(error.localizedDescription)")

            throw E2EIRepositoryFailure.failedToLoadACMEDirectory(error)
        }
    }

    public func getACMENonce(endpoint: String) async throws -> String {
        logger.info("get ACME nonce from \(endpoint)")

        return "temp "
    }

}

enum E2EIRepositoryFailure: Error {

    case failedToLoadACMEDirectory(_ underlyingError: Error)

}
