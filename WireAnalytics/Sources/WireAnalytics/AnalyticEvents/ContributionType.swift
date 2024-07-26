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
public enum ContributionType: String, AnalyticsValue {
    case textMessage = "text_message"
    case likeMessage = "like_message"
    case pingMessage = "ping_message"
    case fileMessage = "file_message"
    case imageMessage = "image_message"
    case locationMessage = "location_message"
    case audioMessage = "audio_message"
    case videoMessage = "video_message"
    case audioCallMessage = "audio_call_message"
    case videoCallMessage = "video_call_message"

    /// A string representation of the contribution type suitable for analytics tracking.
    public var analyticsValue: String {
        rawValue
    }
}
