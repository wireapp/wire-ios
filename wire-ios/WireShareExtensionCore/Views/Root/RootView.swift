//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public struct RootView<
    ViewModel: RootViewModel,
    HomeNode: View
>: View {

    @State
    var viewModel: ViewModel

    @Bindable
    var router: RootRouter

    @ViewBuilder
    let makeHomeNode: (HomeDestination) -> HomeNode

    public var body: some View {
        NavigationStack(path: $router.path) {
            makeHomeNode(HomeDestination())
        }
        .errorAlert($router.errorAlert)
    }
}

#Preview {
    RootView(
        viewModel: RootViewModelImpl(),
        router: RootRouter()
    ) { _ in
        Color.red
    }
}
