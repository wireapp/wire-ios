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

import SwiftUI
import WireFoundation

@MainActor
func cancellationSheetFactory(
    onLeave: @escaping @MainActor @Sendable () -> Void,
    onContinue: @escaping @MainActor @Sendable () -> Void
) -> UIAlertController {
    let alert = UIAlertController(
        title: String.localized(key: "individualToTeam.cancellation.title", bundle: .module),
        message: String.localized(key: "individualToTeam.cancellation.body", bundle: .module),
        preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
    )
    alert.addAction(UIAlertAction(
        title: String.localized(key: "individualToTeam.cancellation.leave", bundle: .module),
        style: .destructive,
        handler: { _ in onLeave() }
    ))
    alert.addAction(UIAlertAction(
        title: String.localized(key: "individualToTeam.cancellation.continue", bundle: .module),
        style: .cancel,
        handler: { _ in onContinue() }
    ))
    alert.view.tintColor = UIColor(.primary)
    return alert
}
