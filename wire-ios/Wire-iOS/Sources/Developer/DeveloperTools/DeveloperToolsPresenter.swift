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

import SwiftUI

final class DeveloperToolsPresenter: NSObject {
    private var displayedDeveloperTools = false

    func presentIfNotDisplayed(
        with router: AppRootRouter?,
        from topMostViewController: @escaping @autoclosure () -> UIViewController?
    ) {
        guard !displayedDeveloperTools else { return }

        let developerTools = UIHostingController(
            rootView: NavigationView {
                DeveloperToolsView(viewModel: DeveloperToolsViewModel(
                    router: router,
                    onDismiss: { [weak self] completion in
                        topMostViewController()?.dismissIfNeeded(completion: completion)
                        self?.displayedDeveloperTools = false
                    }
                ))
            }.navigationViewStyle(.stack)
        )
        developerTools.presentationController?.delegate = self

        topMostViewController()?.present(developerTools, animated: true) { [weak self] in
            self?.displayedDeveloperTools = true
        }
    }
}

extension DeveloperToolsPresenter: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_: UIPresentationController) {
        // called when dismissed by swipe for example
        displayedDeveloperTools = false
    }
}
