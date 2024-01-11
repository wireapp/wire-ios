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

public protocol E2eIRepositoryInterface {

    func createEnrollment(e2eiClientId: E2eIClientID, userName: String, handle: String) async throws -> E2eIEnrollmentInterface
}

public final class E2eIRepository: E2eIRepositoryInterface {

    private let acmeApi: AcmeAPIInterface
    private let apiProvider: APIProviderInterface
    private var e2eiSetupService: E2eISetupServiceInterface
    private let keyRotator: E2eIKeyPackageRotating

    public init(
        acmeApi: AcmeAPIInterface,
        apiProvider: APIProviderInterface,
        e2eiSetupService: E2eISetupServiceInterface,
        keyRotator: E2eIKeyPackageRotating
    ) {
        self.acmeApi = acmeApi
        self.apiProvider = apiProvider
        self.e2eiSetupService = e2eiSetupService
        self.keyRotator = keyRotator
    }

    public func createEnrollment(
        e2eiClientId: E2eIClientID,
        userName: String,
        handle: String
    ) async throws -> E2eIEnrollmentInterface {

        let e2eIdentity = try await e2eiSetupService.setupEnrollment(
            e2eiClientId: e2eiClientId,
            userName: userName,
            handle: handle
        )

        let e2eiService = E2eIService(e2eIdentity: e2eIdentity)
        let acmeDirectory = try await loadACMEDirectory(e2eiService: e2eiService)

        return E2eIEnrollment(
            acmeApi: acmeApi,
            apiProvider: apiProvider,
            e2eiService: e2eiService,
            acmeDirectory: acmeDirectory,
            keyRotator: keyRotator
        )
    }

    private func loadACMEDirectory(e2eiService: E2eIService) async throws -> AcmeDirectory {
        let acmeDirectoryData = try await acmeApi.getACMEDirectory()
        return try await e2eiService.getDirectoryResponse(directoryData: acmeDirectoryData)
    }

}
