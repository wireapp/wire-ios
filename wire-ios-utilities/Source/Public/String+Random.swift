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

    static func randomClientIdentifier(length: UInt = 16) -> String {
        randomAlphanumerical(length: length)
    }

    static func randomDomain(hostLength: UInt = 5) -> String {
        return "\(String.randomAlphanumerical(length: hostLength)).com"
    }

    static func randomRemoteIdentifier(length: UInt = 16) -> String {
        randomAlphanumerical(length: length)
    }
}

// MARK: - Legacy

public extension String {

    // https://github.com/wireapp/wire-ios/pull/920
    // Replacing all random strings didn't work for the some places,
    // so we reverted the change to keep the legacy random func.
    //
    // ClientMessageTests_OTR and ClientMessageTests_OTR_Legacy seem to use rely on a "%llx",
    // but the underlying logic is not clear to me at this point.
    @available(*, deprecated, message: "Better use one of the newer random string methods!")
    static func createLegacyAlphanumerical() -> String {
        String(format: "%llx", arc4random()) // swiftlint:disable:this legacy_random
    }
}
