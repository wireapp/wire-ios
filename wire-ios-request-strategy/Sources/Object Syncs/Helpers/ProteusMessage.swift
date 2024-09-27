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

// MARK: - ProteusMessage

public protocol ProteusMessage: OTREntity, EncryptedPayloadGenerator {
    /// Messages can expire, e.g. if network conditions are too slow to send.
    var shouldExpire: Bool { get }

    /// Sets the expiration date with the default time interval.
    func setExpirationDate()
}

// MARK: - ZMClientMessage + ProteusMessage

extension ZMClientMessage: ProteusMessage {}

// MARK: - ZMAssetClientMessage + ProteusMessage

extension ZMAssetClientMessage: ProteusMessage {}
