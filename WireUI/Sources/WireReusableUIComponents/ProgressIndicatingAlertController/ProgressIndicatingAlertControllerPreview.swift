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

import UIKit

@MainActor
func ProgressIndicatingAlertControllerPreview() -> UIViewController {
    let vc = UIViewController()
    vc.navigationItem.title = "ProgressIndicatingAlertController"

    let label = UILabel()
    label.text = "Hello, World!"
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    vc.view.addSubview(label)
    label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
    label.topAnchor.constraint(equalToSystemSpacingBelow: vc.view.safeAreaLayoutGuide.topAnchor, multiplier: 3).isActive = true

    let alertController = ProgressIndicatingAlertController(
        title: "Creating Backup",
        message: "Saving conversation history...",
        cancelAction: .init(title: "Cancel", handler: {})
    )
    alertController.progress = 0.25

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
        vc.present(alertController, animated: false)
    }

    return UINavigationController(rootViewController: vc)
}
