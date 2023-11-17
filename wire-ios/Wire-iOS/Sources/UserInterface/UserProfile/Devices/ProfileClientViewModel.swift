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
import WireSyncEngine

final class ProfileClientViewModel {
    let userClient: UserClient
    private let getUserClientFingerprint: GetUserClientFingerprintUseCase
    private (set) var fingerprintData: Data?

    var fingerprintDataClosure: ((Data?) -> Void)?

    init(userClient: UserClient, getUserClientFingerprint: GetUserClientFingerprintUseCase? = nil) {
        // TODO: [F] replace when https://github.com/wireapp/wire-ios/pull/674 merged
        guard let useCase = getUserClientFingerprint ?? ZMUserSession.shared()?.getUserClientFingerprint else {
            fatalError("Missing fingerprintUseCase, check the setup")
        }
        self.getUserClientFingerprint = useCase
        self.userClient = userClient
    }

    func loadData() {
        Task {
            self.fingerprintData = await getUserClientFingerprint.invoke(userClient: userClient)

            await MainActor.run { [fingerprintData] in
                self.fingerprintDataClosure?(fingerprintData)
            }
        }
    }
}
