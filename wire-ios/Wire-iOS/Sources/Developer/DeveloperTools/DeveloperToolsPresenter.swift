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
import SwiftUI

class DeveloperToolsPresenter: NSObject {
    private var displayedDeveloperTools = false

    func presentIfNotDisplayed(on application: UIApplication) {

        guard !displayedDeveloperTools else { return }

        let developerTools = UIHostingController(
            rootView: NavigationView {
                DeveloperToolsView(viewModel: DeveloperToolsViewModel(
                    router: AppDelegate.shared.appRootRouter,
                    onDismiss: { [weak self] completion in
                        if let topmostViewController = application.topmostViewController() {
                            topmostViewController.dismissIfNeeded(completion: completion)
                        } else {
                            completion()
                        }
                        self?.displayedDeveloperTools = false
                    }
                ))
            }
        )
        developerTools.presentationController?.delegate = self

        application.topmostViewController()?.present(developerTools, animated: true, completion: { [weak self] in
            self?.displayedDeveloperTools = true
        })
    }
}

extension DeveloperToolsPresenter: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // called when dismissed by swipe for example
        self.displayedDeveloperTools = false
    }
}
