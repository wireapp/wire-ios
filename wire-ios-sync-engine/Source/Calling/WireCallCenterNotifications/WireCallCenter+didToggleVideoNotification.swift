//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

extension WireCallCenterV3 {

    /// A notification that posts when `setVideoState(conversationId:videoState:)` is called on ``WireCallCenterV3``.
    public nonisolated class var didToggleVideoNotification: Notification.Name {
        .init(rawValue: "WireCallCenterV3DidToggleVideoNotification")
    }

    /// The key of the video state value in a notification's `userInfo` dictionary.
    /// The type of the value is ``VideoState``.
    nonisolated static var videoStateUserInfoKey: String { "videoState" }

    func postDidToggleVideoNotification(
        _ notificationCenter: NotificationCenter,
        _ conversationID: AVSIdentifier,
        _ videoState: VideoState
    ) {
        notificationCenter.post(
            name: Self.didToggleVideoNotification,
            object: self,
            userInfo: [
                Self.conversationIDUserInfoKey: conversationID,
                Self.videoStateUserInfoKey: videoState
            ]
        )
    }
}
