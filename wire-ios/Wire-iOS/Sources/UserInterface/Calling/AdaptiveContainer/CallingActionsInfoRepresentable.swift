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

/// UIKit bridge that renders the participants list (security level + header + scrollable list).
/// Always used with `hideActionsView: true`; call action buttons live in `CallPanelView`.
struct CallingActionsInfoRepresentable: UIViewControllerRepresentable {

    let viewModel: CallingContainerViewModel
    @Binding var isExpanded: Bool
    var hideActionsView: Bool = false

    func makeUIViewController(context: Context) -> CallingActionsInfoViewController {
        let vc = CallingActionsInfoViewController(
            participants: viewModel.participants,
            selfUser: viewModel.userSession.selfUser
        )
        vc.additionalSafeAreaInsets = .zero
        return vc
    }

    func updateUIViewController(_ vc: CallingActionsInfoViewController, context: Context) {
        vc.participants = viewModel.participants
        if let configuration = viewModel.callInfoConfiguration {
            vc.didUpdateConfiguration(configuration: configuration)
        }
    }
}
