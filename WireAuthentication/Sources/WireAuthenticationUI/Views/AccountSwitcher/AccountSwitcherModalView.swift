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
import WireDesign
import WireFoundation
import WireMultiBackendUI

package protocol AccountSwitcherFactory {
    @MainActor var viewModel: AccountSwitcherModalViewModel { get }
}

struct AccountSwitcherModalView: View {

    @ObservedObject var viewModel: AccountSwitcherModalViewModel

    init(factory: AccountSwitcherFactory) {
        self._viewModel = ObservedObject(initialValue: factory.viewModel)
    }

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 16) {
                Text(L10n.Localizable.SwitchingAccounts.title)
                    .font(for: .h3)
                    .bold()
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                Text(L10n.Localizable.SwitchingAccounts.subtitle)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(for: .body1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                AccountSwitcherView(
                    otherAccounts: viewModel.accounts,
                    options: [],
                    showLastSeparator: true
                )
            }
            .padding(.bottom, 32)
            .setPreferredSize(navigationBarHidden: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                closeButton
            }
        }
        .background(ColorTheme.Backgrounds.surface.color)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var closeButton: some View {
        Button {
            viewModel.onCloseButtonTapped()
        } label: {
            Image(systemName: "xmark")
        }
    }
}
