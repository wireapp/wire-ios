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

// MARK: - Types

public typealias E2EIEnrollmentResult = Swift.Result<String, Error>

enum Failure: Error, Equatable {

    case failedToLoadACMEDirectory
    case missingNonce
    case failedToCreateAcmeNewAccount

}

public protocol CertificateEnrollmentInterface {

    func invoke(idToken: String) async -> E2EIEnrollmentResult

}

public final class CertificateEnrollment: CertificateEnrollmentInterface {

    var e2eiManager: E2EIManagerInterface

    public init(e2eiManager: E2EIManagerInterface) {
        self.e2eiManager = e2eiManager
    }

    public func invoke(idToken: String) async -> E2EIEnrollmentResult {

        guard let acmeDirectory = await e2eiManager.loadACMEDirectory() else {
            WireLogger.e2ei.warn("Fail to load acme directory")

            return .failure(Failure.failedToLoadACMEDirectory)
        }

        guard let prevNonce = await e2eiManager.getACMENonce(endpoint: acmeDirectory.newNonce) else {
            WireLogger.e2ei.warn("Fail to get acme nonce")

            return .failure(Failure.missingNonce)
        }

        /// update prevNonce?
        guard let newNonce = await e2eiManager.createNewAccount(prevNonce: prevNonce,
                                                                createAccountEndpoint: acmeDirectory.newAccount) else {
            WireLogger.e2ei.warn("Fail to create acme new account")

            return .failure(Failure.failedToCreateAcmeNewAccount)
        }

        return .success("")
    }

}
