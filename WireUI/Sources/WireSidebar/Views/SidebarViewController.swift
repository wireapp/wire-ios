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

    private let model: SidebarAdapterModel

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

    public typealias AccountImageViewBuilder = (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AnyView

    public convenience init(
        accountImageView: @escaping (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AnyView
    ) {
        self.init(accountInfo: .init(), conversationFilter: .none, accountImageView: accountImageView)
    }

    public required init(
        accountInfo: SidebarAccountInfo,
        conversationFilter: SidebarConversationFilter?,
        accountImageView: @escaping (_ accountImage: UIImage, _ availability: SidebarAccountInfo.Availability?) -> AnyView
    ) {
        var self_: SidebarViewController?
        let model = SidebarAdapterModel(
            accountInfo: accountInfo,
            conversationFilter: conversationFilter,
            accountImageAction: { self_?.delegate?.sidebarViewControllerDidSelectAccountImage(self_!) },
            conversationFilterUpdated: { self_?.delegate?.sidebarViewController(self_!, didSelect: $0) },
            connectAction: { self_?.delegate?.sidebarViewControllerDidSelectConnect(self_!) },
            settingsAction: { self_?.delegate?.sidebarViewControllerDidSelectSettings(self_!) },
            supportAction: { self_?.delegate?.sidebarViewControllerDidSelectSupport(self_!) }
        )
        self.model = model
        super.init(rootView: AnyView(SidebarAdapter(model: model, accountImageView: accountImageView)))
        self_ = self
    }

    @available(*, unavailable) @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// MARK: - SidebarAdapter

struct SidebarAdapter<AccountImageView>: View where AccountImageView: View {

    @ObservedObject fileprivate var model: SidebarAdapterModel

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

final class SidebarAdapterModel: ObservableObject {

    @Published var wireTextStyleMapping: WireTextStyleMapping?
    @Published var accountInfo: SidebarAccountInfo
    @Published var conversationFilter: SidebarConversationFilter? {
        didSet { conversationFilterUpdated(conversationFilter) }
    }

    let accountImageAction: () -> Void
    let conversationFilterUpdated: (_ conversationFilter: SidebarConversationFilter?) -> Void
    let connectAction: () -> Void
    let settingsAction: () -> Void
    let supportAction: () -> Void

    init(
        accountInfo: SidebarAccountInfo,
        conversationFilter: SidebarConversationFilter?,
        accountImageAction: @escaping () -> Void,
        conversationFilterUpdated: @escaping (_: SidebarConversationFilter?) -> Void,
        connectAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void,
        supportAction: @escaping () -> Void
    ) {
        self.accountInfo = accountInfo
        self.conversationFilter = conversationFilter
        self.accountImageAction = accountImageAction
        self.conversationFilterUpdated = conversationFilterUpdated
        self.connectAction = connectAction
        self.settingsAction = settingsAction
        self.supportAction = supportAction
    }
}
