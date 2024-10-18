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

@objc(ZMAssertionDumpFile) @objcMembers
public final class AssertionDumpFile: NSObject {

    @available(*, unavailable)
    override public init() {
        fatalError()
    }

    public static var url: URL {
        URL.applicationSupportDirectory.appendingPathComponent("last_assertion.log")
    }

    public static func write(content: String) throws {
        var dumpFile = url
        try Data().write(to: dumpFile)

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try dumpFile.setResourceValues(resourceValues)

        try Data(content.utf8).write(to: dumpFile, options: .atomic)
    }
}
