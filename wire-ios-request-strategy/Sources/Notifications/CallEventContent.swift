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

public struct CallEventContent: Codable {

    public enum CodingKeys: String, CodingKey {

        case type
        case properties = "props"
        case callerUserID = "src_userid"
        case callerClientID = "src_clientid"
        case resp

    }

    // MARK: - Properties

    /// Call event type.

    public let type: String

    /// Properties containing info whether the incoming call has video or not.

    let properties: Properties?

    let callerUserID: String?

    public let callerClientID: String

    public let resp: Bool

    // MARK: - Life cycle

    init(
        type: String,
        properties: Properties?,
        callerUserID: String?,
        callerClientID: String,
        resp: Bool
    ) {
        self.type = type
        self.properties = properties
        self.callerUserID = callerUserID
        self.callerClientID = callerClientID
        self.resp = resp
    }

    public init?(from event: ZMUpdateEvent) {
        guard
            event.type.isOne(of: [.conversationOtrMessageAdd, .conversationMLSMessageAdd]),
            let message = GenericMessage(from: event),
            message.hasCalling,
            let payload = message.calling.content.data(using: .utf8, allowLossyConversion: false)
        else {
            return nil
        }

        self.init(from: payload)
    }

    public init?(from data: Data, with decoder: JSONDecoder = .init()) {
        do {
            self = try decoder.decode(Self.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    // MARK: - Methods

    public var callerID: UUID? {
        callerUserID.flatMap(UUID.init(transportString:))
    }

    public var callState: LocalNotificationType.CallState? {
        if isIncomingCall {
            return .incomingCall(video: properties?.isVideo ?? false)
        } else if isEndCall {
            return .missedCall(cancelled: true)
        } else {
            return nil
        }
    }

    public var initiatesRinging: Bool {
        return isIncomingCall
    }

    public var terminatesRinging: Bool {
        return isEndCall || isAnsweredElsewhere || isRejected
    }

    public var isIncomingCall: Bool {
        return isStartCall && !resp
    }

    public var isAnsweredElsewhere: Bool {
        return isStartCall && resp
    }

    public var isStartCall: Bool {
        return type.isOne(of: ["SETUP", "GROUPSTART", "CONFSTART"])
    }

    public var isEndCall: Bool {
        return type.isOne(of: ["CANCEL", "GROUPEND", "CONFEND"])
    }

    public var isRejected: Bool {
        return type == "REJECT"
    }

    public var isRemoteMute: Bool {
        return type == "REMOTEMUTE"
    }

    public var isConferenceKey: Bool {
        return type == "CONFKEY"
    }

    public var isVideo: Bool {
        guard let properties else {
            return false
        }

        return properties.isVideo
    }

}

extension CallEventContent {

    struct Properties: Codable {

        private let videosend: String

        var isVideo: Bool {
            return videosend == "true"
        }
    }

}

extension ZMUpdateEvent {

    var isCallEvent: Bool {
        return CallEventContent(from: self) != nil
    }

}
