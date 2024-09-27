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

// MARK: - RegistationCredentialVerificationStrategy

final class RegistationCredentialVerificationStrategy: NSObject {
    // MARK: Lifecycle

    init(groupQueue: GroupQueue, status: RegistrationStatusProtocol) {
        self.registrationStatus = status
        super.init()
        self.codeSendingSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: groupQueue)
    }

    // MARK: Internal

    let registrationStatus: RegistrationStatusProtocol
    var codeSendingSync: ZMSingleRequestSync!
}

// MARK: ZMSingleRequestTranscoder

extension RegistationCredentialVerificationStrategy: ZMSingleRequestTranscoder {
    func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        let currentStatus = registrationStatus
        var payload: [String: Any]
        var path: String

        switch currentStatus.phase {
        case let .sendActivationCode(unverifiedEmail):
            path = "/activate/send"
            payload = [
                "email": unverifiedEmail,
                "locale": NSLocale.formattedLocaleIdentifier()!,
            ]

        case let .checkActivationCode(unverifiedEmail, code):
            path = "/activate"
            payload = [
                "email": unverifiedEmail,
                "code": code,
                "dryrun": true,
            ]

        default:
            let phaseString = currentStatus.phase.map { "\($0)" } ?? "<nil>"
            fatal("Generating request for invalid phase: \(phaseString)")
        }

        return ZMTransportRequest(
            path: path,
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if response.result == .success {
            registrationStatus.success()
        } else {
            let error: NSError

            switch registrationStatus.phase {
            case .sendActivationCode:
                let decodedError: NSError?
                decodedError = NSError.domainBlocked(with: response) ??
                    NSError.blacklistedEmail(with: response) ??
                    NSError.emailAddressInUse(with: response) ??
                    NSError.invalidEmail(with: response)
                error = decodedError ?? NSError(userSessionErrorCode: .unknownError, userInfo: [:])

            case .checkActivationCode:
                error = NSError.invalidActivationCode(with: response) ??
                    NSError(userSessionErrorCode: .unknownError, userInfo: [:])

            default:
                let phaseString = registrationStatus.phase.map { "\($0)" } ?? "<nil>"
                fatal("Error occurs for invalid phase: \(phaseString)")
            }
            registrationStatus.handleError(error)
        }
    }
}

// MARK: RequestStrategy

extension RegistationCredentialVerificationStrategy: RequestStrategy {
    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        switch registrationStatus.phase {
        case .checkActivationCode,
             .sendActivationCode:
            codeSendingSync.readyForNextRequestIfNotBusy()
            return codeSendingSync.nextRequest(for: apiVersion)

        default:
            return nil
        }
    }
}
