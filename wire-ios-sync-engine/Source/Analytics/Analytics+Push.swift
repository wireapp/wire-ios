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


extension ZMConversationType {

     var analyticsType: String {
        switch self {
        case .oneOnOne:
            return "one_to_one"
        case .group:
            return "group"
        default:
            return ""
        }
    }
}

public enum ConversationMediaAction: UInt {
    case text, photo, audioCall, videoCall, gif, ping, fileTransfer, videoMessage, audioMessage, location

    public var attributeValue: String {
        switch self {
        case .text:         return "text"
        case .photo:        return "photo"
        case .audioCall:    return "audio_call"
        case .videoCall:    return "video_call"
        case .gif:          return "giphy"
        case .ping:         return "ping"
        case .fileTransfer: return "file"
        case .videoMessage: return "video"
        case .audioMessage: return "audio"
        case .location:     return "location"
        }
    }
}
