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
import PushKit
@testable import WireSyncEngine

// MARK: - PushPayloadMock

final class PushPayloadMock: PKPushPayload {
    let mockDictionaryPayload: [AnyHashable: Any]

    init(dictionaryPayload: [AnyHashable: Any]) {
        self.mockDictionaryPayload = dictionaryPayload

        super.init()
    }

    override var dictionaryPayload: [AnyHashable: Any] {
        mockDictionaryPayload
    }
}

// MARK: - PushCredentialsMock

final class PushCredentialsMock: PKPushCredentials {
    let mockToken: Data
    let mockType: PKPushType

    init(token: Data, type: PKPushType) {
        self.mockToken = token
        self.mockType = type

        super.init()
    }

    override var token: Data {
        mockToken
    }

    override var type: PKPushType {
        mockType
    }
}

// MARK: - PushRegistryMock

@objcMembers
final class PushRegistryMock: PKPushRegistry {
    var mockPushToken: Data?

    func mockIncomingPushPayload(_ payload: [AnyHashable: Any], completion: (() -> Void)? = nil) {
        delegate?.pushRegistry!(
            self,
            didReceiveIncomingPushWith: PushPayloadMock(dictionaryPayload: payload),
            for: .voIP,
            completion: {
                completion?()
            }
        )
    }

    func invalidatePushToken() {
        mockPushToken = nil
        delegate?.pushRegistry?(self, didInvalidatePushTokenFor: .voIP)
    }

    func updatePushToken(_ token: Data) {
        mockPushToken = token
        delegate?.pushRegistry(self, didUpdate: PushCredentialsMock(token: token, type: .voIP), for: .voIP)
    }

    override func pushToken(for type: PKPushType) -> Data? {
        mockPushToken
    }
}
