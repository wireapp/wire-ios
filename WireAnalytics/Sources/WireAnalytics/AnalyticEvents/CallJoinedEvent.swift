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

public struct CallJoinedEvent: AnalyticEvent {

    public var eventName: String {
        "call_joined"
    }

    public var segmentation: [String: String] {
        ["group_type": String(describing: conversationType),
        "is_video_call": String(describing: isVideoCall)]
    }

    public var isVideoCall: Bool
    public var conversationType: ConversationType

}
