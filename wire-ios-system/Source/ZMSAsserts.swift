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
import WireFoundation

/// Reports an error and terminates the application
public func fatal(
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) -> Never {

    let output = NSString(format: "ASSERT: [%s:%d] <%s> %s", "\(file)", Int32(line), "Swift assertion", message) as String

    // report error to datadog or other loggers
    WireLogger.system.critical(output, attributes: .safePublic)

    // prepare and dump to file
    do {
        try AssertionDumpFile.write(content: output)
    } catch {
        assertionFailure(String(reflecting: error))
    }
    fatalError(message, file: file, line: line)
}

/// If the condition is not true, reports an error and terminates the application
public func require(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if !condition {
        fatal(message, file: file, line: line)
    }
}

@objc public enum AppBuild: UInt8 {
    case appStore, debug, develop, unknown

    static var current: AppBuild {
        guard let identifier = Bundle.main.bundleIdentifier else { return .unknown }
        switch identifier {
        case "com.wearezeta.zclient.ios": return .appStore
        case "com.wearezeta.zclient.alpha": return .debug
        case "com.wearezeta.zclient.development": return .develop
        default: return .unknown
        }
    }

    var canFatalError: Bool {
        switch self {
        case .debug, .develop:
            true
        case .appStore, .unknown:
            false
        }
    }
}

/// Terminates the application if the condition is `false` and the current build is not an AppStore build
public func requireInternal(_ condition: Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    guard !condition else { return }
    let errorMessage = message()
    if AppBuild.current.canFatalError {
        fatal(errorMessage, file: file, line: line)
    } else {
        WireLogger.system.critical("requireInternal: \(errorMessage)")
    }
}
