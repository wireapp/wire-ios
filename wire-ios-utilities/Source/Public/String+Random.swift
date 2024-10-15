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

public extension String {

    static func randomAlphanumerical(length: UInt) -> String {
        if length == 0 {
            return String()
        }

        let letters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var s = String()
        for _ in 0..<length {
            s.append(letters.randomElement()!)
        }
        return s
    }

    // TODO: [WPB-11016] Move this test code from production targets
    #if DEBUG
    static func randomClientIdentifier() -> String {
        randomHexadecimal()
    }

    static func randomDomain(hostLength: UInt = 5) -> String {
        return "\(String.randomAlphanumerical(length: hostLength)).com"
    }

    static func randomRemoteIdentifier(length: UInt = 16) -> String {
        randomAlphanumerical(length: length)
    }

    private static func randomHexadecimal() -> String {
        let value = UInt32.random(in: UInt32.min...UInt32.max)
        return String(value, radix: 16)
    }
    #endif
}
