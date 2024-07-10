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

// MARK: - QRCodeView

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: UserQRCodeViewModel

    var body: some View {
        VStack {
            QRCodeCard(viewModel: viewModel)

            InfoText()

            Spacer()

            ShareButtons(viewModel: viewModel)
        }
        .padding(.horizontal, 24)
        .background(Color.primaryViewBackground.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        QRCodeView(viewModel: UserQRCodeViewModel(
            profileLink: "http://link,knfieoqrngorengoejnbgjroqekgnbojqre3bgqjore3bgn3ejjeqrlw3bglrejkbgnjorqwbglejrqg",
            accentColor: .blue,
            handle: "handle"))
    }
}
