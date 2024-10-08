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

    public var selectedMenuItem: SidebarSelectableMenuItem {
        get { model.selectedMenuItem }
        set {
            skipCallingDelegate.toggle()
            model.selectedMenuItem = newValue
            skipCallingDelegate.toggle()
        }
    }

    public var wireAccentColor: WireAccentColor {
        get { model.wireAccentColor }
        set { model.wireAccentColor = newValue }
    }

    public var wireAccentColorMapping: WireAccentColorMapping? {
        get { model.wireAccentColorMapping }
        set { model.wireAccentColorMapping = newValue }
    }

    public var wireTextStyleMapping: WireTextStyleMapping? {
        get { model.wireTextStyleMapping }
        set { model.wireTextStyleMapping = newValue }
    }

    public var sidebarBackgroundColor: UIColor {
        get { model.sidebarBackgroundColor }
        set { model.sidebarBackgroundColor = newValue }
    }

    public var sidebarAccountInfoViewDisplayNameColor: UIColor {
        get { model.sidebarAccountInfoViewDisplayNameColor }
        set { model.sidebarAccountInfoViewDisplayNameColor = newValue }
    }

    public var sidebarAccountInfoViewUsernameColor: UIColor {
        get { model.sidebarAccountInfoViewUsernameColor }
        set { model.sidebarAccountInfoViewUsernameColor = newValue }
    }

    public var sidebarMenuItemTitleForegroundColor: UIColor {
        get { model.sidebarMenuItemTitleForegroundColor }
        set { model.sidebarMenuItemTitleForegroundColor = newValue }
    }

    public var sidebarMenuItemLinkIconForegroundColor: UIColor {
        get { model.sidebarMenuItemLinkIconForegroundColor }
        set { model.sidebarMenuItemLinkIconForegroundColor = newValue }
    }

    public var sidebarMenuItemIsPressedTitleForegroundColor: UIColor {
        get { model.sidebarMenuItemIsPressedTitleForegroundColor }
        set { model.sidebarMenuItemIsPressedTitleForegroundColor = newValue }
    }

    // MARK: - Private Properties

    private var model: SidebarModel!
    private var setupHostingController: (() -> Void)!

    /// A flag which allows skipping the delegate method call for
    /// changes of `selectedMenuItem` coming from outside.
    private var skipCallingDelegate = false

    // MARK: - Life Cycle

    public typealias AccountImageViewBuilder<AccountImageView> = (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    public init(
        accountImageView: @escaping AccountImageViewBuilder<some View>
    ) {
        super.init(nibName: nil, bundle: nil)

        model = .init(accountImageAction: { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectAccountImage(self!)
        }, menuItemAction: { [weak self] menuItem in
            guard let self, !skipCallingDelegate else { return }
            delegate?.sidebarViewController(self, didSelect: menuItem)
        }, connectAction: { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectConnect(self!)
        }, supportAction: { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectSupport(self!)
        })

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
        setupHostingController()
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
            connectAction: model.connectAction,
            supportAction: model.supportAction,
            accountImageView: accountImageView
        )
        .sidebarBackgroundColor(.init(uiColor: model.sidebarBackgroundColor))
        .sidebarAccountInfoViewDisplayNameColor(.init(uiColor: model.sidebarAccountInfoViewDisplayNameColor))
        .sidebarAccountInfoViewUsernameColor(.init(uiColor: model.sidebarAccountInfoViewUsernameColor))
        .sidebarMenuItemTitleForegroundColor(.init(uiColor: model.sidebarMenuItemTitleForegroundColor))
        .sidebarMenuItemLinkIconForegroundColor(.init(uiColor: model.sidebarMenuItemLinkIconForegroundColor))
        .sidebarMenuItemIsPressedTitleForegroundColor(.init(uiColor: model.sidebarMenuItemIsPressedTitleForegroundColor))
        .environment(\.wireAccentColor, model.wireAccentColor)
        .environment(\.wireAccentColorMapping, model.wireAccentColorMapping)
        .environment(\.wireTextStyleMapping, model.wireTextStyleMapping)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    SidebarViewControllerPreviewHelper()
}

@MainActor
private func SidebarViewControllerPreviewHelper() -> UIViewController {
    if UIViewController().traitCollection.userInterfaceIdiom != .pad {
        HintViewController("For previewing please switch to iPad (iOS 17+)!")
    } else {
        SidebarViewControllerPreview()
    }
}
