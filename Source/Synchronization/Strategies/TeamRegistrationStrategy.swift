//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class TeamRegistrationStrategy : NSObject {
    let registrationStatus: RegistrationStatusProtocol
    let userInfoParser: UserInfoParser
    var registrationSync: ZMSingleRequestSync!

    init(groupQueue: ZMSGroupQueue, status : RegistrationStatusProtocol, userInfoParser: UserInfoParser) {
        registrationStatus = status
        self.userInfoParser = userInfoParser
        super.init()
        registrationSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: groupQueue)
    }
}

extension TeamRegistrationStrategy : ZMSingleRequestTranscoder {
    func request(for sync: ZMSingleRequestSync) -> ZMTransportRequest? {
        switch (registrationStatus.phase) {
        case let .createTeam(team: team):
            return ZMTransportRequest(path: "/register", method: .methodPOST, payload: team.payload)
        default:
            fatal("Generating request for invalid phase: \(registrationStatus.phase)")
        }
    }

    func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if response.result == .success {
            userInfoParser.parseUserInfo(from: response)
            registrationStatus.success()
        } else {
            let error = NSError.blacklistedEmail(with: response) ??
                NSError.invalidActivationCode(with: response) ??
                NSError.emailAddressInUse(with: response) ??
                NSError.unauthorizedError(with: response) ??
                NSError.userSessionErrorWith(.unknownError, userInfo: [:])
            registrationStatus.handleError(error)
        }
    }
}

extension TeamRegistrationStrategy : RequestStrategy {
    func nextRequest() -> ZMTransportRequest? {
        switch (registrationStatus.phase) {
        case .createTeam:
            registrationSync.readyForNextRequestIfNotBusy()
            return registrationSync.nextRequest()
        default:
            return nil
        }
    }
}
