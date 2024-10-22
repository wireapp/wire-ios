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

import Countly

extension Countly: CountlyProtocol {

    func start(
        appKey: String,
        host: URL
    ) {
        let config = CountlyConfig()
        config.appKey = appKey
        config.manualSessionHandling = true
        config.host = host.absoluteString
        start(with: config)
    }

    func changeDeviceID(
        _ id: String,
        mergeData: Bool
    ) {
        if mergeData {
            changeDeviceID(withMerge: id)
        } else {
            changeDeviceIDWithoutMerge(id)
        }
    }

    func setUserValue(
        _ value: String?,
        forKey key: String
    ) {
        if let value {
            Countly.user().set(key, value: value)
        } else {
            Countly.user().unSet(key)
        }
    }

}
