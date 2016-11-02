//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cryptobox

public protocol KeyStore {
    
    var encryptionContext : EncryptionContext { get }
    
    /// Generates the last prekey (fallback prekey). This should not be
    /// generated more than once, or the previous last prekey will be invalidated.
    func lastPreKey() throws -> String
    
    /// Generates prekeys in a range. This should not be called more than once
    /// for a given range, or the previously generated prekeys will be invalidated.
    func generatePreKeys(_ count: UInt16 , start: UInt16) throws -> [(id: UInt16, prekey: String)]
    
}
