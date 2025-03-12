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

import SwiftUI
import WireDesign

struct OnPremHeaderView: View {
    @StateObject var viewModel: OnPremHeaderViewModel
    @State private var showCustomBackendAlert = false

    var body: some View {
        Button(action: {
            showCustomBackendAlert.toggle()
        }, label: {
            Text(L10n.OnPremUserLogin.title(viewModel.backendName) + " ")
                .foregroundColor(ColorTheme.Buttons.Secondary.onEnabled.color)
                + Text(Image(systemName: "info.circle"))
                .foregroundColor(.gray)
        })
        .multilineTextAlignment(.center)
        .font(.textStyle(.h2))
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .alert(L10n.OnPremUserLogin.Alert.title, isPresented: $showCustomBackendAlert) {
            Button(L10n.OnPremUserLogin.Alert.button, role: .cancel) {}
        } message: {
            Text(viewModel.backendInfo)
        }
    }
}

#Preview {
    OnPremHeaderView(
        viewModel: OnPremHeaderViewModel(
            backendName: "<Backend name>",
            backendURL: URL(string: "example")!
        )
    )
}
