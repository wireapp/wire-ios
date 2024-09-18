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

public final class SidebarViewController: UIHostingController<AnyView> {

    public weak var delegate: (any SidebarViewControllerDelegate)?

    public var accountInfo: SidebarAccountInfo {
        get { model.accountInfo }
        set { model.accountInfo = newValue }
    }

    public var conversationFilter: SidebarConversationFilter? {
        get { model.conversationFilter }
        set { model.conversationFilter = newValue }
    }

    public var wireTextStyleMapping: WireTextStyleMapping? {
        get { model.wireTextStyleMapping }
        set { model.wireTextStyleMapping = newValue }
    }

    private let model = SidebarModel()

    public required init(
        accountImageView: @escaping (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AnyView
    ) {
        super.init(rootView: AnyView(SidebarAdapter(model: model, accountImageView: accountImageView)))

        model.accountImageAction = { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectAccountImage(self!)
        }
        model.conversationFilterUpdated = { [weak self] conversationFilter in
            self?.delegate?.sidebarViewController(self!, didSelect: conversationFilter)
        }
        model.connectAction = { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectConnect(self!)
        }
        model.settingsAction = { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectSettings(self!)
        }
        model.supportAction = { [weak self] in
            self?.delegate?.sidebarViewControllerDidSelectSupport(self!)
        }
    }

    @available(*, unavailable) @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
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
            conversationFilter: $model.conversationFilter,
            accountImageAction: model.accountImageAction,
            connectAction: model.connectAction,
            settingsAction: model.settingsAction,
            supportAction: model.supportAction,
            accountImageView: accountImageView
        ).environment(\.wireTextStyleMapping, model.wireTextStyleMapping)
    }
}
