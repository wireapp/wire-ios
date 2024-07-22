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

/// An enumeration representing the type of contribution.
public enum ContributionType: AnalyticsValue {
    case textMessage
    case likeMessage
    case pingMessage
    case fileMessage
    case imageMessage
    case locationMessage
    case audioMessage
    case videoMessage
    case audioCallMessage
    case videoCallMessage

    /// A string representation of the contribution type suitable for analytics tracking.
    public var analyticsValue: String {
        switch self {
        case .textMessage: return "text_message"
        case .likeMessage: return "like_message"
        case .pingMessage: return "ping_message"
        case .fileMessage: return "file_message"
        case .imageMessage: return "image_message"
        case .locationMessage: return "location_message"
        case .audioMessage: return "audio_message"
        case .videoMessage: return "video_message"
        case .audioCallMessage: return "audio_call_message"
        case .videoCallMessage: return "video_call_message"
        }
    }
}
