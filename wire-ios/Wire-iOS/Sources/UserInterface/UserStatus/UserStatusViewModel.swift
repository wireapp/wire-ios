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

import WireDataModel

final class UserStatusViewModel {

    struct DisplayModel {
        let options: UserStatusView.Options
        let userStatus: UserStatus
    }

    struct Selection {
        let displayModel: DisplayModel
        let actions: [Action]
    }

    enum Action {
        case notifyAvailabilityChanged(Availability)
        case playSelectionFeedback
        case showAvailabilityExplanation(Availability)
    }

    private let options: UserStatusView.Options
    private let settings: Settings

    var userStatus: UserStatus {
        didSet { displayModel = makeDisplayModel() }
    }

    private(set) var displayModel: DisplayModel

    init(
        options: UserStatusView.Options,
        settings: Settings,
        userStatus: UserStatus = UserStatus()
    ) {
        self.options = options
        self.settings = settings
        self.userStatus = userStatus
        self.displayModel = DisplayModel(options: options, userStatus: userStatus)
    }

    func selectAvailability(_ availability: Availability) -> Selection {
        userStatus.availability = availability

        var actions: [Action] = [
            .notifyAvailabilityChanged(availability),
            .playSelectionFeedback
        ]

        if settings.shouldRemindUserWhenChanging(availability) {
            actions.append(.showAvailabilityExplanation(availability))
        }

        return Selection(displayModel: displayModel, actions: actions)
    }

    private func makeDisplayModel() -> DisplayModel {
        DisplayModel(options: options, userStatus: userStatus)
    }
}
