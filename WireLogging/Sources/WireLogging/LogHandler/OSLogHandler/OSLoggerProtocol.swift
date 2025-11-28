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
import os

/// Protocol abstraction over `os.Logger` to enable testing and mocking.
protocol OSLoggerProtocol: Sendable {
    var subsystem: String { get }
    var category: String { get }
    
    func log(level: OSLogType, _ message: String)
}

/// Concrete implementation wrapping `os.Logger`.
struct OSLoggerWrapper: OSLoggerProtocol, Equatable {
    let subsystem: String
    let category: String
    private let logger: Logger
    
    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    func log(level: OSLogType, _ message: String) {
        logger.log(level: level, "\(message, privacy: .public)")
    }
    
    static func == (lhs: OSLoggerWrapper, rhs: OSLoggerWrapper) -> Bool {
        lhs.subsystem == rhs.subsystem && lhs.category == rhs.category
    }
}

