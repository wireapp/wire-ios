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
import WireDataModel

struct CallViewControllerRepresentable: UIViewControllerRepresentable {

    let viewModel: CallingContainerViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIViewController(context: Context) -> CallViewController {
        let vc = CallViewController(
            voiceChannel: viewModel.voiceChannel,
            selfUser: viewModel.userSession.selfUser,
            isOverlayEnabled: false,
            userSession: viewModel.userSession
        )
        vc.configurationObserver = context.coordinator
        vc.delegate = context.coordinator
        viewModel.callViewController = vc
        return vc
    }

    func updateUIViewController(_ vc: CallViewController, context: Context) {}
}

// MARK: - Coordinator

extension CallViewControllerRepresentable {

    final class Coordinator: NSObject, CallInfoConfigurationObserver, CallViewControllerDelegate {

        private let viewModel: CallingContainerViewModel

        init(viewModel: CallingContainerViewModel) {
            self.viewModel = viewModel
        }

        func didUpdateConfiguration(configuration: CallInfoConfiguration) {
            viewModel.didUpdateConfiguration(configuration)
        }

        func callViewControllerDidDisappear(
            _ callController: CallViewController,
            for conversation: ZMConversation?
        ) {
            viewModel.onHideCallView()
        }
    }
}
