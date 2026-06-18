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

struct CallingActionsInfoRepresentable: UIViewControllerRepresentable {

    let viewModel: CallingContainerViewModel
    @Binding var isExpanded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, isExpanded: $isExpanded)
    }

    func makeUIViewController(context: Context) -> CallingActionsInfoViewController {
        let vc = CallingActionsInfoViewController(
            participants: viewModel.participants,
            selfUser: viewModel.userSession.selfUser
        )
        vc.delegate = context.coordinator
        vc.actionsView.bottomSheetScrollingDelegate = context.coordinator
        vc.additionalSafeAreaInsets = .zero
        return vc
    }

    func updateUIViewController(_ vc: CallingActionsInfoViewController, context: Context) {
        vc.participants = viewModel.participants
        if let configuration = viewModel.callInfoConfiguration {
            vc.didUpdateConfiguration(configuration: configuration)
        }
        vc.setCallingActionsViewDelegate(actionsDelegate: viewModel.callViewController)
    }
}

// MARK: - Coordinator

extension CallingActionsInfoRepresentable {

    final class Coordinator: NSObject, CallingActionsInfoViewControllerDelegate, BottomSheetScrollingDelegate {

        private let viewModel: CallingContainerViewModel
        private let isExpanded: Binding<Bool>

        init(viewModel: CallingContainerViewModel, isExpanded: Binding<Bool>) {
            self.viewModel = viewModel
            self.isExpanded = isExpanded
        }

        // MARK: CallingActionsInfoViewControllerDelegate

        func actionsViewHeightChanged(to height: CGFloat) {
            viewModel.peekHeight = height
        }

        // MARK: BottomSheetScrollingDelegate

        var isBottomSheetExpanded: Bool {
            isExpanded.wrappedValue
        }

        func toggleBottomSheetVisibility() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.wrappedValue.toggle()
            }
        }
    }
}
