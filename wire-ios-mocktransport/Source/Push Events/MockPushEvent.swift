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

@objcMembers
public class MockPushEvent: NSObject {
    // MARK: Lifecycle

    public init(with payload: ZMTransportData, uuid: UUID, isTransient: Bool = false, isSilent: Bool = false) {
        self.payload = payload
        self.uuid = uuid
        self.isTransient = isTransient
        self.isSilent = isSilent
    }

    // MARK: Public

    public let payload: ZMTransportData
    public let uuid: UUID
    public let timestamp = NSDate()
    public let isTransient: Bool
    public let isSilent: Bool

    public var transportData: ZMTransportData {
        [
            "id": uuid.transportString(),
            "payload": [payload],
            "transient": isTransient,
        ] as ZMTransportData
    }

    override public var description: String {
        payload.description
    }

    override public var debugDescription: String {
        "<\(type(of: self))> [\(uuid.transportString())] payload = \(payload)"
    }

    @objc(eventWithPayload:uuid:isTransient:isSilent:)
    public static func event(
        with payload: ZMTransportData,
        uuid: UUID,
        isTransient: Bool,
        isSilent: Bool
    ) -> MockPushEvent {
        MockPushEvent(with: payload, uuid: uuid, isTransient: isTransient, isSilent: isSilent)
    }
}
