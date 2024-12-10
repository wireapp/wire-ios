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

@MainActor
func MainTabBarControllerPreview() -> some MainTabBarControllerProtocol {
    let tabBarController = PreviewTabBarController()
    tabBarController.conversationListUI = .init("conversationList")
    tabBarController.archiveUI = PlaceholderViewController()
    tabBarController.settingsUI = .init()
    tabBarController.selectedContent = .conversations
    return tabBarController
}

private final class PlaceholderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .yellow
        navigationItem.title = navigationController!.tabBarItem.title
        let imageView = UIImageView(image: navigationController!.tabBarItem.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        imageView.transform = .init(scaleX: 3, y: 3)
    }
}
