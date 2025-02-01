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

import WireDesign
import SwiftUI

struct EnterPasswordView: View {

    @StateObject var viewModel: EnterPasswordViewModel

    var body: some View {
        NavigationStack {
            enterPasswordView
                .background(Color(uiColor: ColorTheme.Backgrounds.background))
                .navigationTitle(Text(L10n.Localizable.ImportBackup.EnterPassword.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.cancel()
                        } label: {
                            Text(L10n.Localizable.ImportBackup.Cancel.title)
                        }
                        .foregroundStyle(Color(uiColor: ColorTheme.Base.primary))
                        .accessibilityLabel(Text(L10n.Accessibility.ImportBackup.Cancel.label))
                        .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder
    private var enterPasswordView: some View {
//        VStack {
//            Spacer()
//            HStack {
//                Spacer()
//                Text("TODO")
//                Spacer()
//            }
//            Spacer()
//        }
        Text("TODO")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EnterPasswordPreview()
}
