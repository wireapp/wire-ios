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

import UIKit
import WireReusableUIComponents

protocol SpinnerCapable: AnyObject {
    var dismissSpinner: (() -> Void)? { get set }
}

extension SpinnerCapable where Self: UIViewController {

    var isLoadingViewVisible: Bool {
        get { dismissSpinner != nil }
        set {
            if newValue {
                // do not show double spinners
                guard !isLoadingViewVisible else { return }

                dismissSpinner = presentSpinner()
            } else {
                dismissSpinner?()
                dismissSpinner = nil
            }
        }
    }

    private func presentSpinner(title: String? = nil) -> (() -> Void) {

        let activityIndicator = BlockingActivityIndicator(view: view)
        UIAccessibility.post(notification: .announcement, argument: L10n.Localizable.General.loading)
        Task { @MainActor in
            activityIndicator.start(text: title ?? "")
        }

        return {
            Task { @MainActor in
                activityIndicator.stop()
            }
        }
    }
}
