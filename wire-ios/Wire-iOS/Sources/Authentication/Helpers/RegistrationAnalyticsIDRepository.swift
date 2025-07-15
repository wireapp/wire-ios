//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAuthenticationAPI
import WireFoundation

// TODO: delete file

struct RegistrationAnalyticsIDRepository: RegistrationAnalyticsIDRepositoryProtocol {

    var storage: UserDefaultsProtocol

    func storeAnalyticsID(for userID: UUID, analyticsID: UUID) {
        let privateUserDefaults = PrivateUserDefaults<AnalyticsUserIDDefaultsKey>(userID: userID, storage: storage)
        privateUserDefaults.set(analyticsID.transportString(), forKey: .analyticsIDFromRegistration)
    }

    // func get // TODO: fix

    func deleteAnalyticsID(for userID: UUID) {
        let privateUserDefaults = PrivateUserDefaults<AnalyticsUserIDDefaultsKey>(userID: userID, storage: storage)
        privateUserDefaults.removeObject(forKey: .analyticsIDFromRegistration)
    }

}

private enum AnalyticsUserIDDefaultsKey: String, DefaultsKey {
    case analyticsIDFromRegistration
}
