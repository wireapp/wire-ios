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

// MARK: - RegistrationStrategy

final class RegistrationStrategy: NSObject {
    // MARK: Lifecycle

    init(groupQueue: GroupQueue, status: RegistrationStatusProtocol, userInfoParser: UserInfoParser) {
        self.registrationStatus = status
        self.userInfoParser = userInfoParser
        super.init()
        self.registrationSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: groupQueue)
    }

    // MARK: Internal

    let registrationStatus: RegistrationStatusProtocol
    weak var userInfoParser: UserInfoParser?
    var registrationSync: ZMSingleRequestSync!
}

// MARK: ZMSingleRequestTranscoder

extension RegistrationStrategy: ZMSingleRequestTranscoder {
    func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch registrationStatus.phase {
        case let .createUser(user):
            return ZMTransportRequest(
                path: "/register",
                method: .post,
                payload: user.payload,
                apiVersion: apiVersion.rawValue
            )

        case let .createTeam(team):
            return ZMTransportRequest(
                path: "/register",
                method: .post,
                payload: team.payload,
                apiVersion: apiVersion.rawValue
            )

        default:
            let phaseString = registrationStatus.phase.map { "\($0)" } ?? "<nil>"
            fatal("Generating request for invalid phase: \(phaseString)")
        }
    }

    func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if response.result == .success {
            response.extractUserInfo().map {
                userInfoParser?.upgradeToAuthenticatedSession(with: $0)
            }
            registrationStatus.success()
        } else {
            let error = NSError.blacklistedEmail(with: response) ??
                NSError.invalidActivationCode(with: response) ??
                NSError.emailAddressInUse(with: response) ??
                NSError.invalidEmail(with: response) ??
                NSError.unauthorizedEmailError(with: response) ??
                NSError(userSessionErrorCode: .unknownError, userInfo: [:])
            registrationStatus.handleError(error)
        }
    }
}

// MARK: RequestStrategy

extension RegistrationStrategy: RequestStrategy {
    func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        switch registrationStatus.phase {
        case .createTeam,
             .createUser:
            registrationSync.readyForNextRequestIfNotBusy()
            return registrationSync.nextRequest(for: apiVersion)

        default:
            return nil
        }
    }
}
