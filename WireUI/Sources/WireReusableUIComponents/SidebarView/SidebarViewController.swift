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
public func SidebarViewController(viewModel: SidebarViewModel) -> UIViewController {
    SidebarHostingController(viewModel)
}

private final class SidebarHostingController: UIHostingController<SidebarViewWrapper> {

//    let viewModel: SidebarViewModel
//
//    required init(viewModel: SidebarViewModel) {
//        self.viewModel = viewModel
//        super.init(
//            rootView: .init(
//                accountImage: .init(),
//                isTeamAccount: false,
//                availability: .none,
//                displayName: "",
//                username: ""
//            )
//        )
//    }

    required init(_ viewModel: SidebarViewModel) {
        super.init(rootView: .init(viewModel: viewModel))
    }

    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

private struct SidebarViewWrapper: View {

    @StateObject var viewModel = SidebarViewModel()

    var body: some View {
        SidebarView(
            accountImage: viewModel.accountImage,
            isTeamAccount: viewModel.isTeamAccount,
            availability: viewModel.availability,
            displayName: viewModel.displayName,
            username: viewModel.username
        )
    }
}
