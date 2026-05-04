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

import Foundation

enum HTTPCookieCodec {

    static func encodeCookies(_ cookies: [HTTPCookie]) throws -> Data {
        let properties = cookies.compactMap(\.properties)

        guard
            let name = properties.first?[.name] as? String,
            name == "zuid"
        else {
            throw HTTPCookieCodecError.invalidCookies
        }

        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(properties, forKey: "properties")
        archiver.finishEncoding()

        return archiver.encodedData
    }

    static func decodeData(_ data: Data) throws -> [HTTPCookie] {
        let unarchiver: NSKeyedUnarchiver
        do {
            unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
        } catch {
            throw HTTPCookieCodecError.invalidCookieData(reason: String(describing: error))
        }

        guard let propertyList = unarchiver.decodePropertyList(forKey: "properties") else {
            throw HTTPCookieCodecError.invalidCookieData(reason: "no value for 'properties' key")
        }

        guard let properties = propertyList as? [[HTTPCookiePropertyKey: Any]] else {
            throw HTTPCookieCodecError.invalidCookieData(reason: "'properties' has invalid type")
        }

        return properties.compactMap(HTTPCookie.init)
    }

}
