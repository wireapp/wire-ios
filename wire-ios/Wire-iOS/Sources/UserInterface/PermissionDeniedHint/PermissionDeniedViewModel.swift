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

enum PermissionDeniedViewEvent {
    case primaryButtonTapped
    case secondaryButtonTapped
}

enum PermissionDeniedAction: Equatable {
    case openSettings(permissionType: PermissionDeniedViewModel.PermissionType)
    case skip(permissionType: PermissionDeniedViewModel.PermissionType)
}

final class PermissionDeniedViewModel {

    enum PermissionType: Equatable {
        case notifications
    }

    struct DisplayState: Equatable {
        let permissionType: PermissionType
        let title: String
        let message: String
        let primaryButtonTitle: String
        let secondaryButtonTitle: String
    }

    private let permissionType: PermissionType

    init(permissionType: PermissionType) {
        self.permissionType = permissionType
    }

    var displayState: DisplayState {
        switch permissionType {
        case .notifications:
            typealias RegistrationPushAccessDenied = L10n.Localizable.Registration.PushAccessDenied

            return DisplayState(
                permissionType: permissionType,
                title: RegistrationPushAccessDenied.Hero.title,
                message: RegistrationPushAccessDenied.Hero.paragraph1,
                primaryButtonTitle: RegistrationPushAccessDenied.SettingsButton.title.capitalized,
                secondaryButtonTitle: RegistrationPushAccessDenied.MaybeLaterButton.title.capitalized
            )
        }
    }

    func action(for event: PermissionDeniedViewEvent) -> PermissionDeniedAction {
        switch event {
        case .primaryButtonTapped:
            .openSettings(permissionType: permissionType)
        case .secondaryButtonTapped:
            .skip(permissionType: permissionType)
        }
    }
}

extension PermissionDeniedViewModel {

    static var pushDenied: PermissionDeniedViewModel {
        PermissionDeniedViewModel(permissionType: .notifications)
    }
}
