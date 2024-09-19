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
import WireFoundation

public final class SidebarViewController: UIViewController {

    // MARK: - Public Properties

    public weak var delegate: (any SidebarViewControllerDelegate)?

    public var accountInfo: SidebarAccountInfo {
        get { model.accountInfo }
        set { model.accountInfo = newValue }
    }

    public var selectedMenuItem: SidebarMenuItem {
        get { model.selectedMenuItem }
        set { model.selectedMenuItem = newValue }
    }

    public var wireTextStyleMapping: WireTextStyleMapping? {
        get { model.wireTextStyleMapping }
        set { model.wireTextStyleMapping = newValue }
    }

    // MARK: - Private Properties

    private let model = SidebarModel()
    private var setupHostingController: (() -> Void)?

    // MARK: - Life Cycle

    public typealias AccountImageViewBuilder<AccountImageView> = (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    public init(accountImageView: @escaping AccountImageViewBuilder<some View>) {
        super.init(nibName: nil, bundle: nil)

        model.accountImageAction = { [weak self] in self?.delegate?.sidebarViewControllerDidSelectAccountImage(self!) }
        model.menuItemAction = { [weak self] menuItem in self?.delegate?.sidebarViewController(self!, didSelect: menuItem) }
        model.supportAction = { [weak self] in self?.delegate?.sidebarViewControllerDidSelectSupport(self!) }

        setupHostingController = { [weak self] in
            guard let self else { return }

            let sidebarAdapter = SidebarAdapter(model: model, accountImageView: accountImageView)
            let hostingController = UIHostingController(rootView: sidebarAdapter)
            addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostingController.view)
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                view.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor)
            ])
            hostingController.didMove(toParent: self)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupHostingController?()
    }
}

// MARK: - SidebarAdapter

private struct SidebarAdapter<AccountImageView>: View where AccountImageView: View {

    @ObservedObject fileprivate var model: SidebarModel

    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    var body: some View {
        SidebarView(
            accountInfo: model.accountInfo,
            selectedMenuItem: $model.selectedMenuItem,
            accountImageAction: model.accountImageAction,
            supportAction: model.supportAction,
            accountImageView: accountImageView
        ).environment(\.wireTextStyleMapping, model.wireTextStyleMapping)
    }
}
