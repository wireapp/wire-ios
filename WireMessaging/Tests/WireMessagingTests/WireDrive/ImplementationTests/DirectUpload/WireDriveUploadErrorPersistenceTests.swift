//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import Testing

@testable import WireMessagingDomain

struct WireDriveUploadErrorPersistenceTests {

    private static let allErrors: [WireDriveUploadError] = [
        .fileNotFound,
        .urlError(error: URLError(.timedOut)),
        .other(message: "something went wrong"),
        .serverError(statusCode: 503),
        .unauthorized,
        .insufficientStorage,
        .cancelledBySystem
    ]

    @Test(arguments: allErrors)
    func roundTripsThroughItsPersistedForm(_ error: WireDriveUploadError) throws {
        // When
        let restored = WireDriveUploadError(
            reasonCode: error.reasonCode,
            message: error.reasonMessage
        )

        // Then
        #expect(restored == error)
    }

    @Test
    func decodesNoFailureAsNil() {
        #expect(WireDriveUploadError(reasonCode: .none, message: nil) == nil)
    }

    /// Raw values are written to the database, so they must never drift.
    @Test
    func reasonCodeRawValuesAreStable() {
        #expect(WireDriveUploadError.ReasonCode.none.rawValue == 0)
        #expect(WireDriveUploadError.fileNotFound.reasonCode.rawValue == 1)
        #expect(WireDriveUploadError.urlError(error: URLError(.timedOut)).reasonCode.rawValue == 2)
        #expect(WireDriveUploadError.other(message: "").reasonCode.rawValue == 3)
        #expect(WireDriveUploadError.serverError(statusCode: 500).reasonCode.rawValue == 4)
        #expect(WireDriveUploadError.unauthorized.reasonCode.rawValue == 5)
        #expect(WireDriveUploadError.insufficientStorage.reasonCode.rawValue == 6)
        #expect(WireDriveUploadError.cancelledBySystem.reasonCode.rawValue == 7)
    }

    @Test
    func toleratesAMissingMessage() {
        // Given — a record written by an older build, or corrupted.
        let restored = WireDriveUploadError(reasonCode: .serverError, message: nil)

        // Then
        #expect(restored == .serverError(statusCode: 0))
    }

    // MARK: - Retryability

    /// Without the staged bytes there is nothing left to send.
    @Test
    func fileNotFoundIsNotRetryable() {
        #expect(!WireDriveUploadError.fileNotFound.isRetryable)
    }

    @Test
    func insufficientStorageIsNotRetryable() {
        #expect(!WireDriveUploadError.insufficientStorage.isRetryable)
    }

    @Test(arguments: [500, 502, 503, 599])
    func serverErrorsAreRetryable(_ statusCode: Int) {
        #expect(WireDriveUploadError.serverError(statusCode: statusCode).isRetryable)
    }

    /// Replaying a rejected request unchanged would be rejected the same way.
    @Test(arguments: [400, 404, 409, 413])
    func rejectedRequestsAreNotRetryable(_ statusCode: Int) {
        #expect(!WireDriveUploadError.serverError(statusCode: statusCode).isRetryable)
    }

    @Test
    func transientAndCredentialFailuresAreRetryable() {
        #expect(WireDriveUploadError.urlError(error: URLError(.timedOut)).isRetryable)
        #expect(WireDriveUploadError.other(message: "").isRetryable)
        #expect(WireDriveUploadError.unauthorized.isRetryable)
        #expect(WireDriveUploadError.cancelledBySystem.isRetryable)
    }
}
