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

private let lastAccessTokenKey = "ZMLastAccessToken"
private let lastAccessTokenTypeKey = "ZMLastAccessTokenType"

@objc
extension NSManagedObjectContext {
    public var accessToken: AccessToken? {
        get {
            guard let token = persistentStoreMetadata(forKey: lastAccessTokenKey) as? String,
                  let type = persistentStoreMetadata(forKey: lastAccessTokenTypeKey) as? String else {
                return nil
            }
            return AccessToken(token: token, type: type, expiresInSeconds: 0)
        }

        set {
            setPersistentStoreMetadata(newValue?.token, key: lastAccessTokenKey)
            setPersistentStoreMetadata(newValue?.type, key: lastAccessTokenTypeKey)
        }
    }
}
