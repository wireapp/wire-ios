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

// TODO: delete if possible

public final class DoubleColumnContainerViewController: UIViewController {

    public init(
        primary: UIViewController,
        secondary: UIViewController
    ) {
        super.init(nibName: nil, bundle: nil)

        addChild(primary)
        addChild(secondary)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        for child in children[0 ... 1] {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            child.didMove(toParent: self)
        }

        let (primary, secondary) = (children[0].view!, children[1].view!)
        NSLayoutConstraint.activate([
            primary.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            primary.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: primary.bottomAnchor),

            secondary.leadingAnchor.constraint(equalTo: primary.trailingAnchor),
            secondary.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: secondary.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondary.bottomAnchor),

            primary.widthAnchor.constraint(equalTo: secondary.widthAnchor, multiplier: 2 / 3) // TODO: remove if possible
        ])
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    {
        let vc0 = UIViewController()
        vc0.view.backgroundColor = .green
        vc0.navigationItem.leftBarButtonItems = [.init(systemItem: .bookmarks)]
        vc0.navigationItem.rightBarButtonItems = [.init(systemItem: .compose)]

        let vc1 = UIViewController()
        vc1.view.backgroundColor = .red
        vc1.navigationItem.leftBarButtonItems = [.init(systemItem: .action)]
        vc1.navigationItem.rightBarButtonItems = [.init(systemItem: .camera)]

        let container = DoubleColumnContainerViewController(
            primary: UINavigationController(rootViewController: vc0),
            secondary: UINavigationController(rootViewController: vc1)
        )
        // each part should have their own navigation bar, no common bar
        let navigationController = UINavigationController(rootViewController: container)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }()
}
