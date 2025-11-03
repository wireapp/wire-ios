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
import GenericMessageProtocol
import WireLogging

struct CallContent: Decodable {

    /// Possible values associated with the `type` decoded property
    enum CallType {
        static let setup = "SETUP"
        static let groupStart = "GROUPSTART"
        static let confStart = "CONFSTART"
        static let groupEnd = "GROUPEND"
        static let confEnd = "CONFEND"
        static let cancel = "CANCEL"
        static let reject = "REJECT"
    }

    let type: String
    let properties: Properties?
    let callerUserID: String?
    let callerClientID: String
    let responded: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case properties = "props"
        case callerUserID = "src_userid"
        case callerClientID = "src_clientid"
        case responded = "resp"
    }

    struct Properties: Decodable {
        private let videoSend: String

        enum CodingKeys: String, CodingKey {
            case videoSend = "videosend"
        }

        var isVideo: Bool {
            videoSend == "true"
        }
    }
}

// MARK: Decoding

extension CallContent {
    static func decode(from calling: Calling) -> Self? {
        let decoder = JSONDecoder()

        guard let data = calling.content.data(using: .utf8) else {
            return nil
        }

        do {
            WireLogger.notifications.debug(
                "Checking if a call needs to be handled..",
                attributes: .newNSE
            )
            return try decoder.decode(Self.self, from: data)
        } catch {
            WireLogger.notifications.debug(
                "No call to handle",
                attributes: .newNSE
            )

            return nil
        }
    }
}

// MARK: Call status

extension CallContent {
    var isStartCall: Bool {
        type.isOne(of: [
            CallType.setup,
            CallType.groupStart,
            CallType.confStart
        ])
    }

    var isEndCall: Bool {
        type.isOne(of: [
            CallType.cancel,
            CallType.groupEnd,
            CallType.confEnd
        ])
    }

    var isRejected: Bool {
        type == CallType.reject
    }

    var isIncomingCall: Bool {
        isStartCall && !responded
    }

    var isAnsweredElsewhere: Bool {
        isStartCall && responded
    }

    var isVideo: Bool {
        properties?.isVideo ?? false
    }
}
