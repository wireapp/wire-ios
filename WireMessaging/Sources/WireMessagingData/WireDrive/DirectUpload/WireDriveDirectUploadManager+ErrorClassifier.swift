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

package import Foundation
import WireLogging
package import WireMessagingDomain

package extension WireDriveDirectUploadManager {

    enum Outcome: Sendable, Equatable {

        case succeeded

        /// Start over without telling the user. The transfer never had a fair chance.
        case silentRestart(reason: SilentRestartReason)

        /// Retry automatically, with backoff.
        case transientFailure(WireDriveUploadError)

        /// Stop, and let the user decide.
        case permanentFailure(WireDriveUploadError)

        case cancelledByUser

        package enum SilentRestartReason: Sendable, Equatable {
            /// The presigned URL was rejected or had expired.
            case rePresign
            /// The destination path collided; the pre-check has to run again.
            case rePreCheck
            /// The session lost its connection to `nsurlsessiond`.
            case reattach
        }
    }

    /// Turns an HTTP status and a `URLError` into a decision.
    struct ErrorClassifier: Sendable {

        package static let maximumSilentRestarts = 3
        package static let maximumTransientRetries = 2

        package init() {}

        package func classify(
            statusCode: Int?,
            error: NSError?,
            recordState: WireDriveDirectUploadRecord.State,
            attemptCount: Int
        ) -> Outcome {
            if let error {
                return classify(error: error, recordState: recordState, attemptCount: attemptCount)
            }

            guard let statusCode else {
                // No error and no response is not a state URLSession should produce. Treat it as
                // transient rather than silently marking the upload as done.
                return .transientFailure(.other(message: "upload finished without a response"))
            }

            return classify(statusCode: statusCode, attemptCount: attemptCount)
        }

        private func classify(
            error: NSError,
            recordState: WireDriveDirectUploadRecord.State,
            attemptCount: Int
        ) -> Outcome {
            guard error.domain == NSURLErrorDomain else {
                return .transientFailure(.other(message: error.localizedDescription))
            }

            switch error.code {
            case NSURLErrorCancelled:
                if recordState == .cancelled {
                    return .cancelledByUser
                }

                return attemptCount < Self.maximumSilentRestarts
                    ? .silentRestart(reason: .reattach)
                    : .transientFailure(.cancelledBySystem)

            case NSURLErrorBackgroundSessionWasDisconnected,
                 NSURLErrorBackgroundSessionInUseByAnotherProcess:
                return attemptCount < Self.maximumSilentRestarts
                    ? .silentRestart(reason: .reattach)
                    : .transientFailure(.cancelledBySystem)

            case NSURLErrorTimedOut,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorDataNotAllowed,
                 NSURLErrorCallIsActive:
                return .transientFailure(.urlError(error: URLError(URLError.Code(rawValue: error.code))))

            case NSURLErrorFileDoesNotExist, NSURLErrorNoPermissionsToReadFile:
                // The staged bytes are gone. There is nothing left to send, so a retry cannot help.
                return .permanentFailure(.fileNotFound)

            case NSURLErrorCannotWriteToFile, NSURLErrorCannotCreateFile:
                return .permanentFailure(.insufficientStorage)

            case NSURLErrorUserAuthenticationRequired:
                return attemptCount < Self.maximumSilentRestarts
                    ? .silentRestart(reason: .rePresign)
                    : .permanentFailure(.unauthorized)

            default:
                return .transientFailure(.urlError(error: URLError(URLError.Code(rawValue: error.code))))
            }
        }

        private func classify(statusCode: Int, attemptCount: Int) -> Outcome {
            let canRestartSilently = attemptCount < Self.maximumSilentRestarts

            switch statusCode {
            case 200, 201, 204:
                return .succeeded

            case 401, 403:
                guard canRestartSilently else { return .permanentFailure(.unauthorized) }
                return .silentRestart(reason: .rePresign)

            case 409:
                guard canRestartSilently else {
                    return .permanentFailure(.serverError(statusCode: statusCode))
                }
                return .silentRestart(reason: .rePreCheck)

            case 413, 507:
                return .permanentFailure(.insufficientStorage)

            case 500 ... 599:
                return .transientFailure(.serverError(statusCode: statusCode))

            default:
                return .permanentFailure(.serverError(statusCode: statusCode))
            }
        }
    }
}

// MARK: - Transfer completion

extension WireDriveDirectUploadManager {

    func handleCompletion(
        uploadID: UUID,
        statusCode: Int?,
        responseBody: Data?,
        error: NSError?
    ) async {
        guard let record = records[uploadID] else {
            WireLogger.wireDrive.warn("received a completion for an unknown drive upload")
            return
        }

        let outcome = classifier.classify(
            statusCode: statusCode,
            error: error,
            recordState: record.state,
            attemptCount: record.attemptCount
        )

        if let responseBody, !responseBody.isEmpty, outcome != .succeeded {
            let body = String(decoding: responseBody, as: UTF8.self)
            WireLogger.wireDrive.debug("drive upload rejected with body: \(body)")
        }

        switch outcome {
        case .succeeded:
            progress[uploadID] = 1
            try? fileCache.delete(stagedFileName: record.stagedFileName)
            await transition(uploadID: uploadID) {
                $0.state = .uploaded
                $0.failure = nil
                $0.taskIdentifier = nil
            }
            publishToTracker()

        case let .silentRestart(reason):
            await restart(uploadID: uploadID, reason: reason)

        case let .transientFailure(failure):
            await retryAfterBackoff(uploadID: uploadID, failure: failure)

        case let .permanentFailure(failure):
            await handleFailure(uploadID: uploadID, error: failure)

        case .cancelledByUser:
            progress[uploadID] = nil
            publishToTracker()
        }
    }

    /// Starts the transfer again without surfacing anything to the user.
    func restart(
        uploadID: UUID,
        reason: Outcome.SilentRestartReason
    ) async {
        WireLogger.wireDrive.info("silently restarting drive upload, reason: \(reason)")

        await transition(uploadID: uploadID) { record in
            record.taskIdentifier = nil
            record.failure = nil

            switch reason {
            case .rePreCheck:
                record.state = .staged
                record.nodePath = [record.destinationFolderPath, record.fileName]
                    .joined(separator: "/")
                record.presignedURL = nil
                record.presignedURLExpiresAt = nil

            case .rePresign:
                record.state = .preChecked
                record.presignedURL = nil
                record.presignedURLExpiresAt = nil

            case .reattach:
                record.state = .preChecked
            }
        }

        progress[uploadID] = nil
        publishToTracker()
        await prepareAndStart(uploadIDs: [uploadID])
    }

    func retryAfterBackoff(uploadID: UUID, failure: WireDriveUploadError) async {
        guard let record = records[uploadID] else { return }

        let retriesUsed = max(0, record.attemptCount - 1)
        guard retriesUsed < ErrorClassifier.maximumTransientRetries else {
            await handleFailure(uploadID: uploadID, error: failure)
            return
        }

        let backoff = retryBackoff.isEmpty
            ? 0
            : retryBackoff[min(retriesUsed, retryBackoff.count - 1)]

        await transition(uploadID: uploadID) {
            $0.state = .preChecked
            $0.taskIdentifier = nil
        }
        progress[uploadID] = nil
        publishToTracker()

        scheduleDeferred(uploadID) { [weak self] in
            if backoff > 0 {
                try? await Task.sleep(for: .seconds(backoff))
            }
            await self?.prepareAndStart(uploadIDs: [uploadID])
        }
    }
}
