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

package import SwiftUI
package import WireMessagingDomain

@MainActor
package class ChannelAccessViewModel: ObservableObject {

    @Published var settings: ChannelAccessSettings
    @Published var showPrivateAccessConfirmation = false
    @Published var isLoading: Bool = false

    public var accentColor: Color

    private let useCase: any ChannelAccessUseCaseProtocol

    package init(
        accentColor: Color,
        useCase: any ChannelAccessUseCaseProtocol
    ) {
        self.useCase = useCase
        self.settings = useCase.settings
        self.accentColor = accentColor
    }

    var isPublicDisabled: Bool {
        settings.accessLevel == .private
    }

    var showParticipantPermissions: Bool {
        settings.accessLevel == .private
    }

    func selectAccessLevel(_ level: ChannelAccessLevel) async {
        if level == .private, settings.accessLevel != .private {
            showPrivateAccessConfirmation = true
        } else {
            await applyAccessLevel(level)
        }
    }

    func confirmPrivateAccessChange() async {
        await applyAccessLevel(.private)
    }

    func applyAccessLevel(_ level: ChannelAccessLevel) async {
        isLoading = true
        do {
            settings = try await useCase.updateAccessLevel(to: level)
        } catch {}
        isLoading = false
    }

    func selectParticipantPermission(_ permission: ChannelAccessLevelPermission) async {
        await applyParticipantPermission(permission)
    }

    private func applyParticipantPermission(_ permission: ChannelAccessLevelPermission) async {
        isLoading = true
        do {
            let updatedSettings = try await useCase.updateParticipantPermission(to: permission)
            settings = updatedSettings
        } catch {}
        isLoading = false
    }
}
