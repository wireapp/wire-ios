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

import WireDataModel
import WireFoundation

final class BackendConfigLocalStore: BackendConfigLocalStoreProtocol {

    enum Key: String {
        case isMLSEnabled
    }

    // MARK: - Properties

    private let storage: UserDefaults

    // MARK: - Object lifecycle

    init(sharedUserDefaults: UserDefaults) {
        self.storage = sharedUserDefaults
    }

    // MARK: - Public

    public func storeIsMLSEnabledStatus(newValue: Bool) {
        storage.set(newValue, forKey: Key.isMLSEnabled.rawValue)
    }

    public var isMLSEnabled: Bool {
        storage.bool(forKey: Key.isMLSEnabled.rawValue)
    }

}
