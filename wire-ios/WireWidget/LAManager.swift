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
import ActivityKit

struct AssetAttributes: ActivityAttributes {
    typealias ContentState = AssetUploadState

    var progress: Double
    var name: String
}

public struct AssetUploadState: Codable, Hashable {
    var remainingTime: Double
}



class LiveActivityManager {

    func startUploadingFile(fileName: String) {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("not available")
            return
        }
        let assetAttributes = AssetAttributes(progress: 2, name: fileName)

        let initialContentState = AssetAttributes.ContentState(remainingTime: Double.random(in: 0..<1))

        let activity = ActivityContent(state: initialContentState, staleDate: nil)

        do {
            let statusActivity = try Activity<AssetAttributes>.request(
                attributes: assetAttributes,
                content: activity,
                pushType: nil)
            print("Requested a cab Live Activity \(statusActivity.id)")
        } catch (let error) {
            print("Error requesting a cab Live Activity \(error.localizedDescription)")
        }
    }

    @available(iOS 16.2, *)
    func updateCabStatus() {
        Task {
            let updatedDeliveryStatus = AssetAttributes.ContentState(remainingTime: Double.random(in: 0..<1))
            let activityState = ActivityContent(state: updatedDeliveryStatus, staleDate: .now)

            for activity in Activity<AssetAttributes>.activities{
                await activity.update(activityState)
            }
        }
    }
    @available(iOS 16.2, *)
    func CancelCab() {
        Task {
            for activity in Activity<AssetAttributes>.activities{
                await activity.end(nil,dismissalPolicy:.immediate) // content state set to nil
            }
        }
    }
}
