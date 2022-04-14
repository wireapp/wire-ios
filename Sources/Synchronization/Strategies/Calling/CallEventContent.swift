//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import WireRequestStrategy

struct CallEventContent: Decodable {

    struct Properties: Decodable {
        private let videosend: String

        var isVideo: Bool {
            return videosend == "true"
        }
    }

    /// Call event type
    let type: String

    /// Properties containing infor whether the incoming call has video or not
    let props: Properties?

    /// Caller Id
    let callerIDString: String

    let resp: Bool

    private enum CodingKeys: String, CodingKey {
        case type
        case resp
        case callerIDString = "src_userid"
        case props
    }

    // MARK: - Initialization

     init?(from data: Data) {
         let decoder = JSONDecoder()
         do {
             self = try decoder.decode(Self.self, from: data)
         } catch {
             return nil
         }
     }

    var callerID: UUID? {
        return UUID(uuidString: callerIDString)
    }

    // A call event is considered an incoming call if:
    // 'type' is “SETUP” or “GROUPSTART” or “CONFSTART” and
    // 'resp' is false
    var callState: LocalNotificationType.CallState? {
        if isStartCall && !resp {
            return .incomingCall(video: props?.isVideo ?? false)
        } else if isEndCall {
            return .missedCall(cancelled: true)
        } else {
            return nil
        }
    }

    var isStartCall: Bool {
        return ["SETUP", "GROUPSTART", "CONFSTART"].contains(type)
    }

    var isEndCall: Bool {
        return type == "CANCEL"
    }

 }
