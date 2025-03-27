//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public class ChannelAccessViewModel: ObservableObject {
    @Published var settings: ChannelAccessSettings
    @Published var showPrivateAccessConfirmation = false

    private let useCase: any ChannelAccessUseCase

    public init(useCase: any ChannelAccessUseCase) {
        self.useCase = useCase
        self.settings = useCase.settings
    }

    var isPublicDisabled: Bool {
        settings.isInitiallyPrivate
    }

    var showParticipantPermissions: Bool {
        settings.accessLevel == .private
    }

    func selectAccessLevel(_ level: ChannelAccessLevel) {
        if level == .private && settings.accessLevel != .private {
            showPrivateAccessConfirmation = true
        } else {
            applyAccessLevel(level)
        }
    }

    func confirmPrivateAccessChange() {
        applyAccessLevel(.private)
    }

    private func applyAccessLevel(_ level: ChannelAccessLevel) {
        useCase.updateAccessLevel(to: level)
        settings.accessLevel = level
    }
    
    func selectParticipantPermission(_ permission: ParticipantPermission) {
        useCase.updateParticipantPermission(to: permission)
        settings.participantPermission = permission
    }
}
