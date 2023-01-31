//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

protocol CallGridViewControllerInput {

    var floatingStream: Stream? { get }
    var streams: [Stream] { get }
    var videoState: VideoState { get }
    var networkQuality: NetworkQuality { get }
    var shouldShowActiveSpeakerFrame: Bool { get }
    var presentationMode: VideoGridPresentationMode { get }
    var callHasTwoParticipants: Bool { get }
    var isConnected: Bool { get }
    var isGroupCall: Bool { get }

    func isEqual(to other: CallGridViewControllerInput) -> Bool
}

extension CallGridViewControllerInput where Self: Equatable {
    func isEqual(to other: CallGridViewControllerInput) -> Bool {
        guard let callGridViewControllerInput = other as? Self else { return false }
        return self == callGridViewControllerInput
    }
}

extension CallGridViewControllerInput {

    var allStreamIds: Set<AVSClient> {
        let streamIds = (streams + [floatingStream]).compactMap { $0?.streamId }
        return Set(streamIds)
    }
}
