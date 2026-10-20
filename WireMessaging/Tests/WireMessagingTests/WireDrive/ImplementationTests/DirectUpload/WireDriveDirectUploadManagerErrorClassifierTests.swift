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

@testable import WireMessagingData
@testable import WireMessagingDomain

struct WireDriveDirectUploadManagerErrorClassifierTests {

    private let sut = WireDriveDirectUploadManager.ErrorClassifier()

    // MARK: - HTTP status codes

    @Test(arguments: [200, 201, 204])
    func succeedsOnAcceptedStatusCodes(_ statusCode: Int) {
        #expect(classify(statusCode: statusCode) == .succeeded)
    }

    /// A rejected signature is nearly always an expired presigned URL: its validity is bounded by
    /// the short lived access token it was signed with.
    @Test(arguments: [401, 403])
    func rePresignsOnRejectedCredentials(_ statusCode: Int) {
        #expect(classify(statusCode: statusCode) == .silentRestart(reason: .rePresign))
    }

    @Test(arguments: [401, 403])
    func stopsRePresigningOnceTheBudgetIsSpent(_ statusCode: Int) {
        let outcome = classify(
            statusCode: statusCode,
            attemptCount: WireDriveDirectUploadManager.ErrorClassifier.maximumSilentRestarts
        )
        #expect(outcome == .permanentFailure(.unauthorized))
    }

    @Test
    func rePreChecksOnPathCollision() {
        #expect(classify(statusCode: 409) == .silentRestart(reason: .rePreCheck))
    }

    @Test(arguments: [413, 507])
    func failsPermanentlyWhenTheUploadDoesNotFit(_ statusCode: Int) {
        #expect(classify(statusCode: statusCode) == .permanentFailure(.insufficientStorage))
    }

    @Test(arguments: [500, 502, 503, 599])
    func retriesServerErrors(_ statusCode: Int) {
        #expect(classify(statusCode: statusCode) == .transientFailure(.serverError(statusCode: statusCode)))
    }

    @Test(arguments: [400, 404, 405, 422])
    func failsPermanentlyOnRejectedRequests(_ statusCode: Int) {
        #expect(classify(statusCode: statusCode) == .permanentFailure(.serverError(statusCode: statusCode)))
    }

    // MARK: - Cancellation

    /// A cancel by the user removes the record, so its callback never reaches the classifier.
    @Test
    func restartsAfterAnUnexplainedCancellation() {
        let outcome = classify(error: urlError(NSURLErrorCancelled))
        #expect(outcome == .silentRestart(reason: .reattach))
    }

    @Test
    func surfacesAnUnexplainedCancellationOnceTheBudgetIsSpent() {
        let outcome = classify(
            error: urlError(NSURLErrorCancelled),
            attemptCount: WireDriveDirectUploadManager.ErrorClassifier.maximumSilentRestarts
        )
        #expect(outcome == .transientFailure(.cancelledBySystem))
    }

    @Test
    func reattachesWhenTheBackgroundSessionWasDisconnected() {
        let outcome = classify(error: urlError(NSURLErrorBackgroundSessionWasDisconnected))
        #expect(outcome == .silentRestart(reason: .reattach))
    }

    // MARK: - Network errors

    @Test(arguments: [
        NSURLErrorTimedOut,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorCannotConnectToHost,
        NSURLErrorDNSLookupFailed
    ])
    func retriesNetworkErrors(_ code: Int) {
        let outcome = classify(error: urlError(code))
        #expect(outcome == .transientFailure(.urlError(error: URLError(URLError.Code(rawValue: code)))))
    }

    /// Without the staged bytes there is nothing left to send, so a retry cannot possibly help.
    @Test(arguments: [NSURLErrorFileDoesNotExist, NSURLErrorNoPermissionsToReadFile])
    func failsPermanentlyWhenTheStagedFileIsGone(_ code: Int) {
        #expect(classify(error: urlError(code)) == .permanentFailure(.fileNotFound))
    }

    // MARK: - Malformed completions

    @Test
    func retriesWhenNeitherAStatusNorAnErrorIsReported() {
        let outcome = sut.classify(
            statusCode: nil,
            error: nil,
            attemptCount: 0
        )

        guard case let .transientFailure(failure) = outcome else {
            Issue.record("expected a transient failure, got \(outcome)")
            return
        }

        #expect(failure.isRetryable)
    }

    // MARK: - Helpers

    private func classify(statusCode: Int, attemptCount: Int = 0) -> WireDriveDirectUploadManager.Outcome {
        sut.classify(
            statusCode: statusCode,
            error: nil,
            attemptCount: attemptCount
        )
    }

    private func classify(
        error: NSError,
        attemptCount: Int = 0
    ) -> WireDriveDirectUploadManager.Outcome {
        sut.classify(
            statusCode: nil,
            error: error,
            attemptCount: attemptCount
        )
    }

    private func urlError(_ code: Int) -> NSError {
        NSError(domain: NSURLErrorDomain, code: code)
    }
}
