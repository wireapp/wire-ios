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
import WireLogging

/// Represents the identifer for an MLS group.

public struct MLSGroupID: Equatable, Hashable {

    // MARK: - Properties

    public let data: Data

    // MARK: - Life cycle

    public init?(base64Encoded string: String) {
        guard !string.isEmpty, let data = Data(base64Encoded: string) else { return nil }
        self.init(data)
    }

    public init(_ data: Data) {
        self.data = data
    }
}

// MARK: -

extension MLSGroupID: CustomStringConvertible {

    public var description: String {
        data.base64EncodedString()
    }
}

// MARK: -

extension MLSGroupID: SafeForLoggingStringConvertible {

    public var safeForLoggingDescription: String {
        data.readableHash
    }
}

extension WireLogInterpolation {

    public mutating func appendInterpolation(_ groupID: MLSGroupID, abcd: Bool) {
        if isObfuscationRequired {
            writeText("MLSGroupID(data: \(groupID.data.readableHash))")
        } else {
            writeText("MLSGroupID(data: \(groupID.data.base64EncodedString()))")
        }
    }
}

func loggingExample() {
    let logger = WireLogging.WireLogger.mls
    let groupID = MLSGroupID(base64Encoded: "...")!

//    logger.info("sending commit bundle for group: \(groupID.safeForLoggingDescription)")
//    logger.info("sending commit bundle for group \(groupID)")
}
