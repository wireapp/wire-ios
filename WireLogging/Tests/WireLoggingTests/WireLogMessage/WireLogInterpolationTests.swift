//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import Testing
import WireLoggingAPI

@testable import WireLogging

struct WireLogInterpolationTests {

    @Test func staticStringIsNotObfuscated() async throws {
        let message: WireLogMessage = "Hello, World!"
        #expect(message.content == "Hello, World!")
    }

    @Test func staticStringInterpolationIsNotObfuscated() async throws {
        let name = "World" as StaticString
        let message: WireLogMessage = "Hello, \(name)!"
        #expect(message.content == "Hello, World!")

        // TODO: delete
        let osl = OSLogHandler(subsystem: Bundle.main.bundleIdentifier!)
        let l = WireTaggedLogger(tag: "test", handler: osl)
        l.critical("Lorem \("Ipsum")", .eventID("overridden"))
    }

}

// TODO: move somewhere else? keep in readme/docs?
private struct CustomType {
    var eventID = "012345"
    var sensibleInformation = "Sensitive"
}

extension WireLogInterpolation {

    fileprivate mutating func appendInterpolation(
        _ customType: CustomType,
        selfUserID: UUID
    ) {

        let obfuscationStartIndex = content.index(content.startIndex, offsetBy: 4)
        let obfuscatedContent = content.replacingCharacters(in: obfuscationStartIndex...content.endIndex, with: "***")
        writeText(obfuscatedContent)

        writeAttribute(.eventID(selfUserID.uuidString))
        writeAttribute(.selfUserID(selfUserID.uuidString))
    }

}

extension WireLogAttribute {

    fileprivate static func eventID(_ value: String) -> WireLogAttribute {
        .init(key: "event_id", value: value)
    }

    fileprivate static func selfUserID(_ value: String) -> WireLogAttribute {
        .init(key: "self_user_id", value: value)
    }

}
